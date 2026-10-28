import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import assert from 'node:assert/strict';

export const navigationPattern = /<!-- documentation-navigation -->[\s\S]*?<!-- \/documentation-navigation -->\n*/g;
export const generatedAnchorsPattern = /<!-- documentation-anchors:start -->[\s\S]*?<!-- documentation-anchors:end -->\n*/g;

export function outsideFences(text, transform = line => line) {
  let fence;
  return text.replace(/\r\n/g, '\n').split('\n').map(line => {
    const marker = line.match(/^\s*(`{3,}|~{3,})(.*)$/);
    if (marker && (!fence || (marker[1][0] === fence[0] && marker[1].length >= fence.length && !marker[2].trim()))) {
      fence = fence ? undefined : marker[1];
      return transform === undefined ? '' : line;
    }
    return fence ? line : transform(line);
  }).join('\n');
}

export function prose(text) {
  let fence;
  return text.replace(/\r\n/g, '\n').split('\n').map(line => {
    const marker = line.match(/^\s*(`{3,}|~{3,})(.*)$/);
    if (marker && (!fence || (marker[1][0] === fence[0] && marker[1].length >= fence.length && !marker[2].trim()))) {
      fence = fence ? undefined : marker[1];
      return '';
    }
    return fence ? '' : line;
  }).join('\n');
}

export function slug(text) {
  return text.replace(/<[^>]*>/g, '').replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .toLowerCase().replace(/[^\p{L}\p{M}\p{N}_\-\s]/gu, '').replace(/\s/g, '-');
}

export function headings(text) {
  const counts = new Map();
  return [...prose(text).matchAll(/^(#{1,6})\s+(.+?)\s*#*$/gm)].map(match => {
    const base = slug(match[2]);
    const count = counts.get(base) || 0;
    counts.set(base, count + 1);
    return { level: match[1].length, title: match[2], slug: base + (count ? `-${count}` : '') };
  });
}

export function fencedBlocks(text) {
  const blocks = [];
  let marker, info, lines;
  for (const line of text.replace(/\r\n/g, '\n').split('\n')) {
    const found = line.match(/^\s*(`{3,}|~{3,})(.*)$/);
    if (!marker && found) { marker = found[1]; info = found[2]; lines = []; }
    else if (marker && found && found[1][0] === marker[0] && found[1].length >= marker.length && !found[2].trim()) {
      blocks.push(info + '\n' + lines.join('\n')); marker = undefined;
    } else if (marker) lines.push(line);
  }
  if (marker) throw new Error('Unclosed fenced block');
  return blocks;
}

export function links(text) {
  const body = prose(text).replace(/(`+)[\s\S]*?\1/g, '');
  return [...body.matchAll(/!?\[[^\]]*\]\((<[^>]+>|[^\s)]+)(?:\s+["'][^)]*["'])?\)/g)].map(m => m[1].replace(/^<|>$/g, ''))
    .concat([...body.matchAll(/^\s*\[[^\]]+\]:\s*(\S+)/gm)].map(m => m[1]))
    .concat([...body.matchAll(/<(?:a|img)\b[^>]*\b(?:href|src)=["']([^"']+)["'][^>]*>/gi)].map(m => m[1]));
}

export function inlineLiterals(text) {
  return [...prose(text.replace(navigationPattern, '').replace(generatedAnchorsPattern, '')).matchAll(/(`+)([\s\S]*?)\1/g)]
    .map(match => match[2].replace(/\s*\n\s*/g, ' ')).sort();
}

function anchors(text) {
  return new Set(headings(text).map(h => h.slug).concat([...prose(text).matchAll(/\bid=["']([^"']+)["']/g)].map(m => m[1])));
}

export function validate(manifest, documents, files) {
  const errors = [], pages = new Map(), graph = new Map();
  let localLinks = 0, examples = 0, sections = 0, literals = 0, localizedDiagrams = 0;
  const directories = new Set(['.']);
  for (const name of files) {
    let dir = path.posix.dirname(name);
    while (dir !== '.') { directories.add(dir); dir = path.posix.dirname(dir); }
  }
  for (const pair of manifest.pages) {
    if (pair.hu !== pair.en.replace(/\.md$/, '-hu.md') || pair.en.endsWith('-hu.md')) errors.push(`Invalid pair: ${pair.en}`);
    for (const locale of ['en', 'hu']) {
      if (pages.has(pair[locale])) errors.push(`Duplicate page: ${pair[locale]}`);
      pages.set(pair[locale], locale);
    }
  }
  for (const name of files) if (/\.(?:md|markdown)$/i.test(name) && !pages.has(name)) errors.push(`Unpaired Markdown page: ${name}`);
  for (const pair of manifest.pages) {
    if (!documents.has(pair.en) || !documents.has(pair.hu)) { errors.push(`Missing language counterpart: ${pair.en} / ${pair.hu}`); continue; }
    const en = documents.get(pair.en), hu = documents.get(pair.hu);
    const enHeads = headings(en), huHeads = headings(hu);
    sections += enHeads.length;
    if (!enHeads.length || !huHeads.length || JSON.stringify(enHeads.map(h => h.level)) !== JSON.stringify(huHeads.map(h => h.level))) errors.push(`Heading structure differs: ${pair.en}`);
    try {
      const a = fencedBlocks(en), b = fencedBlocks(hu); examples += a.length;
      const localized = new Set(pair.localizedTextBlocks || []);
      if (a.length !== b.length) errors.push(`Fenced examples differ: ${pair.en}`);
      for (const index of localized) {
        if (!Number.isInteger(index) || !a[index]?.startsWith('text\n') || !b[index]?.startsWith('text\n')) errors.push(`Invalid localized diagram: ${pair.en} block ${index}`);
        else localizedDiagrams++;
      }
      if (JSON.stringify(a.filter((_, index) => !localized.has(index))) !== JSON.stringify(b.filter((_, index) => !localized.has(index)))) errors.push(`Fenced examples differ: ${pair.en}`);
    } catch (error) { errors.push(`${pair.en}: ${error.message}`); }
    const tableRows = text => prose(text).split('\n').filter(line => /^\s*\|/.test(line)).length;
    if (tableRows(en) !== tableRows(hu)) errors.push(`Table coverage differs: ${pair.en}`);
    const a = inlineLiterals(en), b = inlineLiterals(hu); literals += a.length;
    if (JSON.stringify(a) !== JSON.stringify(b)) errors.push(`Inline code literals differ: ${pair.en}`);
  }
  for (const [name, locale] of pages) {
    const text = documents.get(name); if (text === undefined) continue;
    graph.set(name, new Set());
    const nav = text.match(navigationPattern)?.[0];
    const pair = manifest.pages.find(item => item[locale] === name);
    const expectedSelectors = [
      `[English](${path.posix.relative(path.posix.dirname(name), pair.en)})`,
      `[Magyar](${path.posix.relative(path.posix.dirname(name), pair.hu)})`,
    ];
    if (!nav || !expectedSelectors.every(selector => nav.includes(selector))) errors.push(`Missing reciprocal language navigation: ${name}`);
    const remainingNavigation = expectedSelectors.reduce((rest, selector) => rest.replace(selector, ''), nav || '');
    const entries = links(text.replace(navigationPattern, '')).map(href => ({ href, isNavigation: false }))
      .concat(links(remainingNavigation).map(href => ({ href, isNavigation: false })))
      .concat(expectedSelectors.filter(selector => nav?.includes(selector)).flatMap(selector => links(selector)).map(href => ({ href, isNavigation: true })));
    for (const { href, isNavigation } of entries) {
      if (/^(?:https?:|mailto:|data:)/i.test(href)) continue;
      let target, fragment;
      try {
        const split = href.indexOf('#');
        const pathname = split < 0 ? href : href.slice(0, split);
        fragment = split < 0 ? '' : decodeURIComponent(href.slice(split + 1));
        target = pathname ? path.posix.normalize(path.posix.join(path.posix.dirname(name), decodeURIComponent(pathname))).replace(/\/$/, '') : name;
      } catch { errors.push(`Invalid URL in ${name}: ${href}`); continue; }
      localLinks++;
      if (!files.has(target) && !directories.has(target)) { errors.push(`Missing target in ${name}: ${href}`); continue; }
      if (documents.has(target)) {
        graph.get(name).add(target);
        if (fragment && !anchors(documents.get(target)).has(fragment)) errors.push(`Missing anchor in ${name}: ${href}`);
        if (pages.get(target) !== locale && !isNavigation) errors.push(`Wrong-language link in ${name}: ${href}`);
      }
    }
  }
  for (const locale of ['en', 'hu']) {
    const seen = new Set(), queue = [manifest.entrypoints[locale]];
    while (queue.length) {
      const name = queue.pop(); if (seen.has(name)) continue; seen.add(name);
      for (const next of graph.get(name) || []) if (pages.get(next) === locale) queue.push(next);
    }
    for (const pair of manifest.pages) if (!seen.has(pair[locale])) errors.push(`Unreachable ${locale} page: ${pair[locale]}`);
  }
  return { pairs: manifest.pages.length, pages: pages.size, sections, fencedBlocks: examples, identicalExamples: examples - localizedDiagrams, localizedDiagrams, inlineLiterals: literals, localLinks, errors };
}

function selfTest() {
  const manifest = { entrypoints: { en: 'README.md', hu: 'README-hu.md' }, pages: [{ en: 'README.md', hu: 'README-hu.md' }] };
  const nav = '<!-- documentation-navigation -->\n[English](README.md) | [Magyar](README-hu.md)\n<!-- /documentation-navigation -->';
  const en = `# Guide\n${nav}\n\n[Run](#doc-run)\n<a id="doc-run"></a>\n## Run\n\n\`\`\`json\n{"enabled":false}\n\`\`\`\n`;
  const hu = en.replace('# Guide', '# Útmutató').replace('## Run', '## Futtatás');
  const documents = new Map([['README.md', en], ['README-hu.md', hu]]), files = new Set(documents.keys());
  const check = (docs = documents, inventory = files) => validate(manifest, docs, inventory).errors;
  assert.deepEqual(check(), []);
  assert(check(new Map([['README.md', en]])).some(e => e.includes('Missing language counterpart')));
  assert(check(new Map([['README.md', en.replace('#doc-run', '#missing')], ['README-hu.md', hu]])).some(e => e.includes('Missing anchor')));
  assert(check(new Map([['README.md', en + '\n[Wrong language](README-hu.md)'], ['README-hu.md', hu]])).some(e => e.includes('Wrong-language link')));
  assert(check(new Map([['README.md', en.replace('<!-- /documentation-navigation -->', '[Documentation](README-hu.md)\n<!-- /documentation-navigation -->')], ['README-hu.md', hu]])).some(e => e.includes('Wrong-language link')));
  assert(check(new Map([['README.md', en + '\n[Missing](missing.md)'], ['README-hu.md', hu]])).some(e => e.includes('Missing target')));
  assert(check(new Map([['README.md', en + '\n[Missing\npage](missing.md)'], ['README-hu.md', hu]])).some(e => e.includes('Missing target')));
  assert(check(new Map([['README.md', en + '\n`different`'], ['README-hu.md', hu]])).some(e => e.includes('Inline code literals differ')));
  assert(check(new Map([['README.md', en], ['README-hu.md', hu.replace('false', 'true')]])).some(e => e.includes('Fenced examples differ')));
  const localizedManifest = { ...manifest, pages: [{ ...manifest.pages[0], localizedTextBlocks: [0] }] };
  assert(validate(localizedManifest, documents, files).errors.some(e => e.includes('Invalid localized diagram')));
  const diagramDocs = new Map([['README.md', en.replace('json\n{"enabled":false}', 'text\nEnglish diagram')], ['README-hu.md', hu.replace('json\n{"enabled":false}', 'text\nMagyar ábra')]]);
  assert.deepEqual(validate(localizedManifest, diagramDocs, files).errors, []);
  assert(check(documents, new Set([...files, 'orphan.md'])).some(e => e.includes('Unpaired')));
  assert(check(documents, new Set([...files, 'FOREIGN.MD'])).some(e => e.includes('Unpaired')));
  assert(check(documents, new Set([...files, 'foreign.markdown'])).some(e => e.includes('Unpaired')));
  const more = { ...manifest, pages: [...manifest.pages, { en: 'other.md', hu: 'other-hu.md' }] };
  const otherDocs = new Map([...documents, ['other.md', en.replaceAll('README', 'other')], ['other-hu.md', hu.replaceAll('README', 'other')]]);
  assert(validate(more, otherDocs, new Set(otherDocs.keys())).errors.some(e => e.includes('Unreachable')));
  assert(links('```md\n[x](missing.md)\n```\n[x](README.md)').length === 1);
  console.log('Documentation validator self-checks passed (valid graph, missing pair/target/anchor, wrong language, changed code/literal, orphan, unreachable page, fenced-link exclusion).');
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv.includes('--self-test')) selfTest();
  else {
    const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
    const manifest = JSON.parse(fs.readFileSync(path.join(root, 'docs/documentation-languages.json'), 'utf8'));
    const names = execFileSync('git', ['ls-files', '-z', '--cached', '--others', '--exclude-standard'], { cwd: root, encoding: 'utf8' }).split('\0').filter(Boolean);
    const documents = new Map(manifest.pages.flatMap(pair => [pair.en, pair.hu]).filter(name => fs.existsSync(path.join(root, name))).map(name => [name, fs.readFileSync(path.join(root, name), 'utf8')]));
    const result = validate(manifest, documents, new Set(names));
    console.log(JSON.stringify(result, null, 2));
    if (result.errors.length) process.exitCode = 1;
  }
}
