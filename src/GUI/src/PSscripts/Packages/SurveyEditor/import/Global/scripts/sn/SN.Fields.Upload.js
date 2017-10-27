// using $skin/scripts/sn/sn.fields.js
// using $skin/scripts/jquery/plugins/fileupload/jquery.ui.widget.js
// using $skin/scripts/jquery/plugins/fileupload/jquery.iframe-transport.js
// using $skin/scripts/jquery/plugins/fileupload/jquery.fileupload.js
// using $skin/scripts/sn/SN.Upload.js
// using $skin/scripts/OverlayManager.js
// resource Action
// template SurveyList

SN.Fields.Upload = {
    name: 'upload',
    title: SN.Resources.SurveyList["UploadQuestion-DisplayName"],
    icon: 'upload',
    editor: {
        schema: {
            fields: {
                Type: { type: 'string', defaultValue: 'Reference' },
                Control: { type: 'string', defaultValue: 'Upload' },
                Id: { type: 'string' },
                Title: { type: 'string', defaultValue: SN.Resources.SurveyList["UntitledQuestion"] },
                Hint: { type: 'string' },
                Required: { type: 'boolean', defaultValue: false },
                References: { type: 'array', defaultValue: [] },
                AllowMultiple: { type: 'boolean', defaultValue: false },
                Settings: {
                    AllowMultiple: {
                        defaultValue: false,
                        type: 'boolean',
                        title: SN.Resources.SurveyList["AllowMultiple"]
                    },
                    template: SN.Templates.SurveyList["uploadSettings.html"],
                    render: function ($question) {
                        var $settingsRow = $question.find('.sn-survey-question-inner');
                        var survey = $('#surveyContainer').data('Survey');
                        var id = $question.closest('.sn-survey-section').attr('id');
                        var section = survey.getSectionById(id);
                        var questionId = $question.attr('id');
                        var question = survey.getQuestionById(section, questionId);
                        var timeoutId;
                        $settingsRow.find('input').on('click', function () {
                            var $this = $(this);
                            clearTimeout(timeoutId);
                            timeoutId = setTimeout(function () {
                                question.AllowMultiple = $this.is(":checked");
                            }, 500);
                        });
                        survey.saveDataToTextBox();
                    }
                },
                SNFields: [
                        { 'DisplayName': 'Title' },
                        { 'Description': 'Hint' },
                        { 'Compulsory': 'Required' },
                        { 'AllowMultiple': 'AllowMultiple' }],
                Validation: {
                    Type: { type: "dropdown", index: 0, value: 'text' },
                    Rule: { type: "dropdown", cascadeFrom: 'Type', index: 1, value: 'nofile' },
                    Value: { type: "string", index: 2 },
                    ErrorMessage: { type: "string", index: 3, placeHolder: SN.Resources.SurveyList["ErrorMessage-NoFile"] }
                }
            },
            validation: {
                fields: {
                    Type: [
                        {
                            name: 'text',
                            text: '',
                            defaultValue: '',
                            rules: [
                                {
                                    name: 'nofile',
                                    text: SN.Resources.SurveyList["NoFile"],
                                    value: true,
                                    type: 'number',
                                    method: function (e) {
                                        var validate = e.data('nofile');
                                        var required = typeof e.attr('custom-required') !== 'undefined';
                                        if (typeof validate !== 'undefined' && validate !== false && required) {
                                            var fileNumber = $(e).closest('.sn-question').find('.sn-upload-uploadedbar').length;
                                            return (fileNumber > 0);
                                        }
                                        return true;
                                    }
                                }
                            ]
                        }
                    ]
                }
            }
        },
        template: SN.Templates.SurveyList["uploadEditor.html"],
        menu: [
            { field: 'Hint', text: SN.Resources.SurveyList["Hint-Menu"] }
        ]
    },
    fill: {
        template: SN.Templates.SurveyList["uploadFill.html"],
        render: function (id, mode, question, path) {
            var survey = $('#surveyContainer').data('Survey');
            if (mode !== 'editor') {
                var $question = $('[data-qid="' + id + '"]');
                var uploaddata = [];
                var maxChunkSize = 1048576;

                var iosregex = "^(?:(?:(?:Mozilla/\\d\\.\\d\\s*\\()+|Mobile\\s*Safari\\s*\\d+\\.\\d+(\\.\\d+)?\\s*)(?:iPhone(?:\\s+Simulator)?|iPad|iPod);\\s*(?:U;\\s*)?(?:[a-z]+(?:-[a-z]+)?;\\s*)?CPU\\s*(?:iPhone\\s*)?(?:OS\\s*\\d+_\\d+(?:_\\d+)?\\s*)?(?:like|comme)\\s*Mac\\s*O?S?\\s*X(?:;\\s*[a-z]+(?:-[a-z]+)?)?\\)\\s*)?(?:AppleWebKit/\\d+(?:\\.\\d+(?:\\.\\d+)?|\\s*\\+)?\\s*)?(?:\\(KHTML,\\s*(?:like|comme)\\s*Gecko\\s*\\)\\s*)?(?:Version/\\d+\\.\\d+(?:\\.\\d+)?\\s*)?(?:Mobile/\\w+\\s*)?(?:Safari/\\d+\\.\\d+(\\.\\d+)?.*)?$";
                var isios = new RegExp(iosregex).test(navigator.userAgent);
                var overwrite = !isios;
                var backUrl = '<%= string.IsNullOrEmpty(PortalContext.Current.BackUrl) ? PortalContext.Current.ContextNodePath : PortalContext.Current.BackUrl %>';
                var folderId = '<%= PortalContext.Current.ContextNodeHead.Id %>';

                function isUniqueFileName(filename, idx) {
                    for (var i = 0; i < uploaddata.length; i++) {
                        if (i == idx)
                            continue;
                        if (uploaddata[i].files[0].name == filename)
                            return false;
                    }
                    return true;
                }

                var count = 0;
                var inProgress = false;

                var $progress = $question.find('#progress');

                var folderPath = odata.dataRoot + odata.getItemUrl(path + '/Files-' + question.Id);
                $question.find('#sn-upload-fileupload').attr('data-url', folderPath + '/Upload');

                $question.find('#sn-upload-fileupload').fileupload({
                    maxChunkSize: maxChunkSize,
                    dataType: 'json',
                    progress: function (e, data) {

                        inProgress = true;
                        var progress = parseInt(data.loaded / data.total * 100, 10);
                        progress = progress > 100 ? 100 : progress;
                        $('.sn-upload-bar', data.context).css('width', progress + '%');

                    },
                    add: function (e, data) {
                        var allowedMultiple = question.AllowMultiple;
                        if ((!allowedMultiple && $question.find('.sn-upload-fileprogress').length === 0) || allowedMultiple) {
                            checkLocalstorage(data);

                            count += 1;
                            var filename, filetype;
                            if (data.files[0].name && data.files[0].name.length > 0) {
                                if ($.browser.msie && parseInt($.browser.version, 10) > 6 && parseInt($.browser.version, 10) < 10) {
                                    var inputValue = data.fileInput[0].value.split('\\');
                                    filename = inputValue[inputValue.length - 1];
                                }
                                else {
                                    filetype = data.files[0].type.split('/')[1];
                                    filename = data.files[0].name;
                                }
                            }
                            else {
                                filetype = data.files[0].type.split('/')[1];
                                filename = 'image' + count + '.' + filetype;
                            }
                            var title = '<div class="sn-upload-header"><div class="sn-upload-filetitle">' + filename + '</div><div class="sn-upload-cancelfile"><img src="/Root/Global/images/icons/16/delete.png"></div><div class="sn-upload-clear"></div></div>';
                            var error = '<div class="sn-upload-error"></div>';
                            var progress = '<div class="sn-upload-progressbar"><div class="sn-upload-bar" style="width: 0%;"></div></div>';
                            data.context = $('<div class="sn-upload-fileprogress">' + title + error + '<div class="sn-upload-progress">' + progress + '</div></div>').appendTo($progress);
                            uploaddata.push(data);

                            $('#sn-upload-startbutton').removeClass('sn-submit-disabled');

                            $('.sn-upload-cancelfile', data.context).on('click', function () {
                                cancelFile(data);
                                deleteFile(path + '/Files-' + question.Id, filename);
                            });

                            $('.sn-closebutton').on('click', function () {
                                if (inProgress) {
                                    if ($('.overlay').length === 0) {
                                        overlayManager.showOverlay({
                                            text: '<%= SenseNetResourceManager.Current.GetString("Controls", "AboortUploadFull")%>'
                                        });
                                    }
                                    $popup = $('.overlay');

                                    $popup.find('.buttonRow').css({ 'text-align': 'right', 'margin-top': '20px' });
                                    $popup.find('.sn-abortbutton').css('margin-right', '10px');

                                    $popup.find('.sn-abortbutton').on('click', function () {
                                        cancelFile(data);
                                        overlayManager.hideOverlay();
                                        window.location = backUrl;
                                    });
                                    $popup.find('.sn-cancel').on('click', function () {
                                        overlayManager.hideOverlay();
                                    });
                                }
                                else {
                                    window.location = backUrl;
                                }
                            });
                            uploadFile(uploaddata.length - 1);
                            //data.submit();
                        }
                        else {
                            overlayManager.hideOverlay();
                            var $overlay = overlayManager.showOverlay({
                                text: '<span class="fa fa-warning"></span>' + SN.Resources.SurveyList["MultipleFileUploadIsNotAllowed"],
                                cssClass: "popup-error",
                                appendCloseButton: true
                            });
                        }
                    },
                    fail: function (e, data) {
                        var $error = $('.sn-upload-error', data.context);
                        var json = (data.jqXHR.responseText) ? jQuery.parseJSON(data.jqXHR.responseText) : data.result;
                        if (typeof (json) == 'undefined') {
                            $error.text($('#sn-upload-othererror').text());
                        } else {
                            $error.text(json.error.message.value);
                        }
                        $error.show();
                        inProgress = false;
                    },
                    done: function (e, data) {
                        inProgress = false;
                        var json = (data.jqXHR.responseText) ? jQuery.parseJSON(data.jqXHR.responseText) : data.result;
                        $('.sn-upload-bar', data.context).addClass('sn-upload-uploadedbar');

                        var filename = json.Name;
                        var url = json.Url;
                        $('.sn-upload-filetitle', data.context).html('<a href="' + url + '">' + filename + '</a>');

                        SN.Upload.uploadFinished(data.formData.ChunkToken);
                        question.References.push(json.Id);
                    }
                });

                function checkLocalstorage(d) {
                    var fileName = d.files[0].name;
                    SN.Upload.removeItemByKey(SN.Upload.getItemByName(fileName));
                }

                function uploadFile(index) {
                    var url = $question.find('#sn-upload-fileupload').attr('data-url');

                    var contentType = 'File';

                    (function () {
                        var idx = index;
                        var currentData = uploaddata[idx];

                        // first request creates the file
                        var filename, filetype;
                        if ($.browser.msie && parseInt($.browser.version, 10) > 6 && parseInt($.browser.version, 10) < 10) {
                            filetype = currentData.files[0].name.split('\\')
                            filetype = filetype[filetype.length - 1];
                        }
                        else
                            filetype = currentData.files[0].type.split('/')[1];
                        if (filetype === 'jpeg')
                            filetype === 'jpg';
                        if (currentData.files[0].name && currentData.files[0].name.length > 0) {
                            filename = currentData.files[0].name;
                        }
                        else {
                            filename = 'image' + (i + 1) + '.' + filetype;
                        }

                        var filelength = currentData.files[0].size;
                        var currentOverwrite = false;

                        // if two or more files of the same name have been selected to upload at once, we switch off overwrite for these files
                        if (!isUniqueFileName(filename, idx))
                            currentOverwrite = false;

                        $.ajax({
                            url: url + '?create=1',
                            type: 'POST',

                            data: {
                                "ContentType": contentType,
                                "FileName": filename,
                                "Overwrite": currentOverwrite,
                                "UseChunk": filelength > maxChunkSize,
                                "PropertyName": "Binary",
                                "FileLength": filelength
                            },
                            success: function (data) {
                                // set formdata and submit upload request
                                currentData.formData = {
                                    "FileName": filename,
                                    "Overwrite": currentOverwrite,
                                    "ContentType": contentType,
                                    "ChunkToken": data,
                                    "PropertyName": "Binary",
                                    "FileLength": filelength
                                };
                                currentData.submit();
                            },
                            error: function (data) {
                                var $error = $('.sn-upload-error', currentData.context);
                                if (typeof (data) == 'undefined') {
                                    $error.text($('#sn-upload-othererror').text());
                                } else {
                                    var result = jQuery.parseJSON(data.responseText);
                                    $error.text(result.error.message.value);
                                }
                                $error.show();
                            }
                        });
                    })();
                    uploaddata = [];
                    $('#sn-upload-startbutton').addClass('sn-submit-disabled');
                }

                function cancelFile(data) {
                    // abort requests
                    if (data.jqXHR)
                        data.jqXHR.abort();

                    // remove from uploaddata
                    var idx = uploaddata.indexOf(data);
                    if (idx != -1)
                        uploaddata.splice(idx, 1);

                    // remove from dom
                    data.context.remove();

                    if (uploaddata.length == 0)
                        $('#sn-upload-startbutton').addClass('sn-submit-disabled');
                }

                function deleteFile(folderPath, fileName) {
                    var o = {};
                    o.path = folderPath + '/' + fileName;
                    o.params = [{ permanent: true }];
                    odata.deleteContent(o);
                }
            }
        },
        value: function ($question, questionId) {
            var survey = $('#surveyContainer').data('Survey');
            var id = $question.closest('.sn-survey-section').attr('id');
            var section = survey.getSectionById(id);
            var question = survey.getQuestionById(section, questionId);
            return question.References;
        }
    }
}