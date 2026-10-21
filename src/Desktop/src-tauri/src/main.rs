#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use rand::RngCore;
use std::{
    error::Error,
    fs,
    net::{Ipv4Addr, TcpListener},
    path::PathBuf,
    process::{Child, Command, Stdio},
    sync::{atomic::{AtomicBool, Ordering}, Arc, Mutex},
    thread,
    time::{Duration, Instant},
};
use tauri::{Manager, WebviewUrl, WebviewWindowBuilder};
use tauri_plugin_dialog::{DialogExt, MessageDialogButtons, MessageDialogKind};

/// The child belongs to this desktop instance. No browser session owns a run.
struct LocalService {
    child: Mutex<Child>,
    origin: String,
    token: String,
    stopping: AtomicBool,
}

impl LocalService {
    fn stop(&self) {
        if self.stopping.swap(true, Ordering::SeqCst) { return; }
        let client = reqwest::blocking::Client::builder()
            .timeout(Duration::from_secs(2)).no_proxy().build();
        if let Ok(client) = client {
            let _ = client.post(format!("{}/api/lifecycle/shutdown", self.origin))
                .bearer_auth(&self.token).header("X-Plot-Request", "1").send();
        }
        if let Ok(mut child) = self.child.lock() {
            let deadline = Instant::now() + Duration::from_secs(5);
            while Instant::now() < deadline {
                if child.try_wait().ok().flatten().is_some() { return; }
                thread::sleep(Duration::from_millis(100));
            }
            // Only this instance's process tree is stopped. A forced stop is not rollback.
            #[cfg(windows)]
            {
                use std::os::windows::process::CommandExt;
                let _ = Command::new("taskkill")
                    .args(["/PID", &child.id().to_string(), "/T", "/F"])
                    .creation_flags(0x08000000).stdout(Stdio::null()).stderr(Stdio::null()).status();
            }
            #[cfg(unix)]
            unsafe { libc::kill(-(child.id() as i32), libc::SIGKILL); }
            let _ = child.kill();
            let _ = child.wait();
        }
    }
}

impl Drop for LocalService {
    fn drop(&mut self) { self.stop(); }
}

fn start_service(app: &tauri::App, smoke: bool) -> Result<Arc<LocalService>, Box<dyn Error>> {
    let mut probe = Command::new("pwsh");
    probe.args(["-NoProfile", "-NonInteractive", "-Command", "if ($PSVersionTable.PSVersion.Major -lt 7) { exit 1 }"])
        .stdout(Stdio::null()).stderr(Stdio::null());
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        probe.creation_flags(0x08000000);
    }
    let pwsh = probe.status();
    if !pwsh.map(|status| status.success()).unwrap_or(false) {
        return Err("PowerShell 7 (pwsh) must be installed and available on PATH. See the management deployment guide.".into());
    }
    let resources = app.path().resource_dir()?;
    let data = if smoke {
        PathBuf::from(std::env::var("PLOTMANAGER_DESKTOP_SMOKE_DATA")?)
    } else { app.path().app_local_data_dir()? };
    fs::create_dir_all(&data)?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(&data, fs::Permissions::from_mode(0o700))?;
    }
    let executable: PathBuf = resources.join("service").join(if cfg!(windows) { "PlotManager.Server.exe" } else { "PlotManager.Server" });
    if !executable.is_file() || !resources.join("engine/Invoke-ManagedRequest.ps1").is_file() {
        return Err("The bundled service or native engine is missing. Rebuild with Build-Management.ps1 -Desktop.".into());
    }
    // The socket is selected on loopback only. A startup race fails closed on readiness.
    let socket = TcpListener::bind((Ipv4Addr::LOCALHOST, 0))?;
    let port = socket.local_addr()?.port();
    let origin = format!("http://127.0.0.1:{port}");
    let mut token_bytes = [0_u8; 32];
    rand::rngs::OsRng.fill_bytes(&mut token_bytes);
    let token: String = token_bytes.iter().map(|b| format!("{b:02x}")).collect();
    let mut command = Command::new(executable);
    command.current_dir(resources.join("service"))
        .env("ASPNETCORE_URLS", &origin)
        .env("PLOTMANAGER_MODE", "local")
        .env("PLOTMANAGER_TOKEN", &token)
        .env("PLOTMANAGER_DATA", &data)
        .env("PLOTMANAGER_PROJECT_ROOT", data.join("projects"))
        .env("PLOTMANAGER_ENGINE", resources.join("engine"))
        .env("PLOTMANAGER_PARENT_PID", std::process::id().to_string())
        .stdin(Stdio::null()).stdout(Stdio::null()).stderr(Stdio::null());
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        command.creation_flags(0x08000000);
    }
    #[cfg(unix)]
    {
        use std::os::unix::process::CommandExt;
        command.process_group(0);
    }
    drop(socket);
    let service = Arc::new(LocalService { child: Mutex::new(command.spawn()?), origin, token, stopping: AtomicBool::new(false) });
    let client = reqwest::blocking::Client::builder().timeout(Duration::from_millis(500)).no_proxy().build()?;
    let deadline = Instant::now() + Duration::from_secs(30);
    loop {
        // Readiness requires our unpredictable credential, not merely an unrelated open port.
        if client.get(format!("{}/api/runner", service.origin)).bearer_auth(&service.token).send()
            .map(|response| response.status().is_success()).unwrap_or(false) { break; }
        if service.child.lock().unwrap().try_wait()?.is_some() {
            return Err("The local service exited during startup. Check its prerequisites and data-directory permissions.".into());
        }
        if Instant::now() >= deadline {
            service.stop();
            return Err("The local service did not become ready within 30 seconds.".into());
        }
        thread::sleep(Duration::from_millis(150));
    }
    Ok(service)
}

fn main() {
    let smoke = std::env::args().any(|argument| argument == "--smoke-test");
    let builder = tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .setup(move |app| {
            let service = match start_service(app, smoke) {
                Ok(service) => service,
                Err(error) => {
                    if smoke { eprintln!("Desktop smoke startup failed: {error}"); std::process::exit(1); }
                    let message = error.to_string();
                    app.dialog().message(message).title("Plot Manager could not start")
                        .kind(MessageDialogKind::Error).show(|_| std::process::exit(1));
                    return Ok(());
                }
            };
            let url = format!("{}/#token={}", service.origin, service.token).parse()?;
            let permitted_origin = service.origin.clone();
            let close_pending = Arc::new(AtomicBool::new(false));
            let window = WebviewWindowBuilder::new(app, "main", WebviewUrl::External(url))
                .title("Plot Manager — local runner").inner_size(1280.0, 850.0).min_inner_size(880.0, 600.0)
                .visible(!smoke)
                .on_navigation(move |url| url.origin().ascii_serialization() == permitted_origin)
                .build()?;
            app.manage(service);
            if smoke {
                let smoke_window = window.clone();
                let smoke_handle = app.handle().clone();
                thread::spawn(move || {
                    let deadline = Instant::now() + Duration::from_secs(45);
                    let mut ready = false;
                    while Instant::now() < deadline {
                        let (sender, receiver) = std::sync::mpsc::channel();
                        if smoke_window.eval_with_callback(
                            "!!document.querySelector('[data-testid=\"management-ready\"]') && !window.location.hash.includes('token=')",
                            move |value| { let _ = sender.send(value); }
                        ).is_ok() && receiver.recv_timeout(Duration::from_secs(2)).ok().as_deref() == Some("true") {
                            ready = true;
                            break;
                        }
                        thread::sleep(Duration::from_millis(200));
                    }
                    let service = smoke_handle.state::<Arc<LocalService>>();
                    service.stop();
                    let stopped = service.child.lock().unwrap().try_wait().ok().flatten().is_some();
                    if let Ok(output) = std::env::var("PLOTMANAGER_DESKTOP_SMOKE_OUTPUT") {
                        let _ = fs::write(output, format!("{{\"webviewReady\":{ready},\"serviceStopped\":{stopped},\"protocolVersion\":1}}\n"));
                    }
                    smoke_handle.exit(if ready && stopped { 0 } else { 1 });
                });
            }
            let handle = app.handle().clone();
            window.on_window_event(move |event| {
                if let tauri::WindowEvent::CloseRequested { api, .. } = event {
                    api.prevent_close();
                    if close_pending.swap(true, Ordering::SeqCst) { return; }
                    let handle = handle.clone();
                    let close_pending = close_pending.clone();
                    handle.clone().dialog().message("Closing this desktop window stops its local service and any running workers. A stopped process does not roll back completed operations; external jobs may continue. Close Plot Manager?")
                        .title("Stop the local runner?").kind(MessageDialogKind::Warning)
                        .buttons(MessageDialogButtons::OkCancelCustom("Close and stop".into(), "Keep open".into()))
                        .show(move |yes| {
                            if yes {
                                let handle = handle.clone();
                                thread::spawn(move || {
                                    handle.state::<Arc<LocalService>>().stop();
                                    handle.exit(0);
                                });
                            } else { close_pending.store(false, Ordering::SeqCst); }
                        });
                }
            });
            Ok(())
        });
    match builder.build(tauri::generate_context!()) {
        Ok(app) => app.run(|handle, event| {
            if let tauri::RunEvent::Exit = event {
                if let Some(service) = handle.try_state::<Arc<LocalService>>() { service.stop(); }
            }
        }),
        Err(error) => { eprintln!("Plot Manager desktop initialization failed: {error}"); std::process::exit(1); }
    }
}
