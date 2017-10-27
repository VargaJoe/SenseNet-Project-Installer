// using $skin/scripts/ODataManager.js
// using $skin/scripts/OverlayManager.js
// using $skin/scripts/sn/SN.Fields.ShortAnswer.js
// using $skin/scripts/sn/SN.Fields.Number.js
// using $skin/scripts/sn/SN.Fields.WholeNumber.js
// using $skin/scripts/sn/SN.Fields.Paragraph.js
// using $skin/scripts/sn/SN.Fields.DateTime.js
// using $skin/scripts/sn/SN.Fields.Switch.js
// using $skin/scripts/sn/SN.Fields.Range.js
// using $skin/scripts/sn/SN.Fields.Radio.js
// using $skin/scripts/sn/SN.Fields.DropDown.js
// using $skin/scripts/sn/SN.Fields.Checkbox.js
// using $skin/scripts/sn/SN.Fields.Grid.js
// using $skin/scripts/sn/SN.Fields.Upload.js
// using $skin/scripts/sn/SN.Fields.OptionalText.js
// using $skin/scripts/sn/sn.controls.js
// resource SurveyList
// template SurveyList

(function ($) {
    "use strict";
    $.Survey = function (el, options) {
        var survey = this;
        survey.$el = $(el);
        survey.el = el;
        if (survey.$el.data('Survey'))
            return;

        survey.$el.data('Survey', survey);

        if (typeof odata === 'undefined')
            var odata = new SN.ODataManager({
                timezoneDifferenceInMinutes: null
            });

        if (typeof overlayManager === 'undefined')
            var overlayManager = new OverlayManager(200, "sn-popup");

        //private variables
        var surveyPath = options.path || null;
        var $surveyTitle = options.title || null;
        var surveyTitle;
        if ($surveyTitle && typeof $surveyTitle === 'object') {
            surveyTitle = $surveyTitle.val();
            if (surveyTitle.length === 0)
                surveyTitle = SN.Resources.SurveyList["Untitled-Survey"];
        }
        else
            surveyTitle = options.title || SN.Resources.SurveyList["Untitled-Survey"];

        var $surveyDescription = options.description || null;
        var surveyDescription = '';
        if ($surveyDescription && typeof $surveyDescription === 'object')
            surveyDescription = $surveyDescription.val();
        else
            surveyDescription = options.description || '';

        var $intro = options.intro || null;
        var intro = '';
        if ($intro && typeof $intro === 'object')
            intro = $intro.val();
        else
            intro = options.intro || '';

        var $outro = options.outro || null;
        var outro = '';
        if ($outro && typeof $outro === 'object')
            outro = $outro.val();
        else
            outro = options.outro || '';

        var $structure = options.structure || '';
        var structure, structureJSON, validator;
        if ($structure && typeof $structure === 'object') {
            if ($structure.val().length === 0) {
                structureJSON = {
                    ProgressBar: false,
                    OnlySingleResponse: false,
                    Sections: [
                        {
                            id: 'intro',
                            title: SN.Resources.SurveyList["IntroductionText"],
                            index: 0
                        },
                        {
                            id: 'outro',
                            title: SN.Resources.SurveyList["EndText"],
                            index: 100,
                            landingPage: '',
                            afterSubmit: ''
                        }
                    ]
                };
                structure = JSON.stringify(structureJSON);
            }
            else
                structure = $structure.val();

            try {
                structureJSON = JSON.parse(structure);
            } catch (e) {
                $.error('The given JSON is not valid!');
            }
        }
        else if (typeof $structure === 'string') {
            if ($structure.length === 0)
                structure = '{"Sections": []}';
            else
                structure = $structure;

            try {
                structureJSON = JSON.parse(structure);
            } catch (e) {
                $.error('The given JSON is not valid!');
            }
        }
        else
            $.error('The given textbox is empty!');

        var $form = survey.$el;
        var kendoProgressBar = null, validationItem = null, savedFieldsNumber = 0;
        var questionTypes = SN.Fields;
        if (typeof options.customTypes !== 'undefined' && options.customTypes.length > 0)
            addCustomTypes(options.customTypes);

        var $saveButton = $('#SaveButton');
        var $cancelButton = $('#CancelButton');
        var loadingPreview = false;
        var templates = SN.Templates.SurveyList;

        var errorTemplate = options.errorTemplate || templates["error.html"];

        var view = survey.$el.attr('data-view');
        var notValid = false;
        var settings = options.settings || [];
        if (typeof structureJSON.settings === 'undefined')
            structureJSON.settings = {};
        var settingsToSave = {
        };

        survey.init = function () {
            if (errorTemplate) {
                validator = $form.kendoValidator({
                    errorTemplate: errorTemplate,
                    messages: {
                        required: SN.Resources.SurveyList["RequiredField"]
                    }
                }).data("kendoValidator");
            }

            if (view === 'edit' || view === 'new') {
                survey.initEditor();
                survey.initSettings();
            }
            else
                survey.initSurvey();

            $form.kendoSortable({
                filter: ">div.draggable",
                handler: ".sn-survey-section-header",
                cursor: "move",
                placeholder: sectionListReorderPlaceholder,
                hint: sectionListReorderHint,
                end: saveSectionOrder
            });

            $saveButton.on('click', function () {
                if (view === 'new')
                    survey.saveSurvey();
                else if (view === 'edit')
                    survey.modifySurvey();
            });

            $cancelButton.on('click', function () {
                window.location.href = surveyPath;
            });
        };

        survey.initEditor = function () {

            survey.initSurveySettings();
            initSectionAdding();

            //init sections
            for (var i = 0; i < structureJSON.Sections.length; i++) {
                var section = new Section(structureJSON.Sections[i]);
                survey.renderSurveySection(section);
            }
        };

        survey.initSurvey = function () {
            SN.Controls.H1.render($form, {
                info: '',
                mode: 'browse',
                label: decodeString(surveyTitle)
            });
            if (surveyDescription.length > 0)
                SN.Controls.Paragraph.render($form, {
                    label: SN.Resources.SurveyList["Description-DisplayName"],
                    info: '',
                    mode: 'browse',
                    value: surveyDescription
                });

            if (structureJSON.ProgressBar &&
                ((typeof intro !== undefined && intro.length !== 0) ||
                    (structureJSON.Sections.length - 2 > 1)))
                survey.initProgressbar();

            loadSections();
        };

        survey.initSurveySettings = function () {
            var $surveySettings = $(templates["section.html"]).appendTo($form);
            $surveySettings.addClass('sn-survey-settings');
            var deleteSection ={
                   deleteSection: SN.Resources.SurveyList["DeleteSection"] }
            var sectionHeaderTemplate = kendo.template(templates["sectionHeader.html"]);
            var templatedHeader = sectionHeaderTemplate(deleteSection);
            var $header = $(templatedHeader).prependTo($surveySettings);
            $header.find('.sn-survey-section-title')
                   .text(SN.Resources.SurveyList["SurveySettingsTitle"]);
            $header.find('.sn-survey-section-menu').remove();
            var $inner = $surveySettings.find('.sn-survey-section-inner');

            SN.Controls.H1.render($inner, {
                placeholder: SN.Resources.SurveyList["DisplayName-DisplayName"],
                info: '',
                mode: 'edit',
                value: decodeString(surveyTitle),
                save: saveDefaultFieldData,
                data: $surveyTitle,
                key: 'displayname'
            });
            SN.Controls.Paragraph.render($inner, {
                placeholder: SN.Resources.SurveyList["Description-DisplayName"],
                info: '',
                mode: 'edit',
                //value: surveyDescription,
                save: saveDefaultFieldData,
                data: $surveyDescription,
                value: surveyDescription,
                extraAttr: 'data-autoresize',
                key: 'description'
            });

            SN.Controls.Switch.render($inner, {
                label: SN.Resources.SurveyList["Progressbar-DisplayName"],
                value: structureJSON.ProgressBar || false,
                save: setBooleanValue,
                data: structureJSON,
                info: '',
                key: 'ProgressBar',
                change: onProgressChange
            });

            SN.Controls.Switch.render($inner, {
                label: SN.Resources.SurveyList["OnlySingleResponse-DisplayName"],
                value: structureJSON.OnlySingleResponse || false,
                save: setBooleanValue,
                data: structureJSON,
                info: SN.Resources.SurveyList["OnlySingleResponse-Description"],
                key: 'OnlySingleResponse'
            });
        };

        survey.renderSurveySection = function (section, id) {
            var $section;
            if (typeof id !== 'undefined')
                $section = $(templates["section.html"]).insertAfter('.sn-survey-section#' + id);
            else
                $section = $(templates["section.html"]).appendTo($form);

            $section.attr({ 'id': section.id, 'data-index': section.index });
            if (section.id !== 'intro' && section.id !== 'outro') {
                $section.addClass('draggable');
            }
            var deleteSection = {
                deleteSection: SN.Resources.SurveyList["DeleteSection"]
            }
            var sectionHeaderTemplate = kendo.template(templates["sectionHeader.html"]);
            var templatedHeader = sectionHeaderTemplate(deleteSection);
            var $sectionHeader = $(templatedHeader).prependTo($section);
            //var $sectionFooter = $(sectionFooterTemplate).appendTo($section);
            var $sectionInner = $section.find('.sn-survey-section-inner');

            if (section.id === 'intro')
                $sectionHeader.find('.sn-survey-section-title')
                              .text(SN.Resources.SurveyList["Intro-Title"]);
            else if (section.id === 'outro')
                $sectionHeader.find('.sn-survey-section-title')
                              .text(SN.Resources.SurveyList["Outro-Title"]);
            else
                $sectionHeader.find('.sn-survey-section-title')
                              .text(SN.Resources.SurveyList["Section"] +
                                    ' ' + section.index + '/' +
                                    (structureJSON.Sections.length - 2));

            //loadJumpToSelect($jumptoSelect, section.id, section.jumpto, section.index);

            var $copySection = $sectionHeader.find('.sn-icon-duplicate');
            var $deleteSection = $sectionHeader.find('.sn-icon-delete');
            var $toggleSection = $sectionHeader.find('.sn-icon-toggle');

            $section.on('mousedown', function (e) {
                if ($(e.target).hasClass('sn-icon-duplicate'))
                    return;
                survey.selectSection(section.id);
                var $addNewQuestionButton = $('.addNewQuestionButton');
                // show "add new question" menu if an editable section is selected
                if (!$(e.target).closest($section).hasClass('draggable')) {
                    if (!$addNewQuestionButton.hasClass('hidden'))
                        $addNewQuestionButton.addClass('hidden');
                } else {
                    if ($addNewQuestionButton.hasClass('hidden'))
                        $addNewQuestionButton.removeClass('hidden');
                }
            });

            $('body').on('click', function (e) {
                if ($(e.target).hasClass('sn-survey-new-question')) {
                    return;
                }
                if ($(e.target).hasClass('sn-icon-new-question')) {
                    $('.sn-survey-new-question').removeClass('visible');
                    $(e.target).closest('.sn-survey-section')
                               .find('.sn-survey-new-question')
                               .addClass('visible');
                    return;
                }
                if ($(e.target).closest('.sn-survey-new-question').length)
                    return;

                $('.sn-survey-new-question').removeClass('visible');
            });

            $copySection.on('click', function () {
                survey.copySection(section);
            });
            $deleteSection.on('click', function () {
                deleteSectionConfirmation(section.id, survey.deleteSection);
            });
            $toggleSection.on('click', function () {
                survey.toggleSection(section.id);
            });

            if (section.id === 'intro')
                SN.Controls.Paragraph.render($sectionInner, {
                    label: SN.Resources.SurveyList["Intro-DisplayName"],
                    info: '',
                    mode: 'edit',
                    value: intro,
                    save: saveDefaultFieldData,
                    data: $intro
                });
            else if (section.id === 'outro') {
                SN.Controls.Paragraph.render($sectionInner, {
                    label: SN.Resources.SurveyList["Outro-DisplayName"],
                    info: '',
                    mode: 'edit',
                    value: outro,
                    save: saveDefaultFieldData,
                    data: $outro
                });
                var outroSection = survey.getSectionById('outro');
                SN.Controls.SingleReference.render($sectionInner, {
                    label: SN.Resources.SurveyList["OutroLink-DisplayName"],
                    info: SN.Resources.SurveyList["OutroLink-Description"],
                    mode: 'edit',
                    key: 'landingPage',
                    treeRoot: ['/Root'],
                    data: survey.$el.find('#textbox-landingPage'),
                    save: setReferenceValue,
                    value: outroSection.landingPage
                });
                SN.Controls.Textarea.render($sectionInner, {
                    label: SN.Resources.SurveyList["AfterSubmit-DisplayName"],
                    info: SN.Resources.SurveyList["AfterSubmit-Description"],
                    mode: 'edit',
                    key: 'afterSubmit',
                    data: survey.$el.find('#textbox-afterSubmit'),
                    save: setTextareaValue,
                    extraClass: 'warning',
                    value: decodeString(outroSection.afterSubmit)
                });
            }
            else {
                SN.Controls.String.render($sectionInner, {
                    label: '',
                    value: decodeString(section.title),
                    mode: 'edit',
                    extraClass: '',
                    save: setStringValue,
                    data: structureJSON.Sections[section.index + 1],
                    info: '',
                    key: 'title',
                    required: true
                });
                SN.Controls.Textarea.render($sectionInner, {
                    label: '',
                    placeholder: SN.Resources.SurveyList["SectionDescription-DisplayName"],
                    mode: 'edit',
                    extraClass: '',
                    save: setStringValue,
                    data: structureJSON.Sections[section.index + 1],
                    info: '',
                    key: 'description',
                    value: decodeString(section.description),
                    extraAttr: 'data-autoresize'
                });
                SN.Controls.String.render($sectionInner, {
                    value: decodeString(section.hint),
                    mode: 'edit',
                    extraClass: 'sn-input-hint',
                    save: setStringValue,
                    data: structureJSON.Sections[section.index + 1],
                    info: '',
                    key: 'hint',
                    placeholder: SN.Resources.SurveyList["SectionHint-PlaceHolder"]
                });
            }
            $('#intro').find('.sn-icon-duplicate, .sn-icon-delete, .sn-icon-new-question').remove();
            $('#outro').find('.sn-icon-duplicate, .sn-icon-delete, .sn-icon-new-question').remove();


            var $questionContainer = $('<div class="sn-survey-questions"></div>')
                                        .appendTo($sectionInner);
            if (typeof section.questions !== 'undefined' && section.questions.length > 0) {
                loadQuestions($questionContainer, section.questions);
            }

            $questionContainer.kendoSortable({
                filter: ">div.sn-survey-question",
                handler: ".sn-survey-question-header",
                cursor: "move",
                placeholder: questionListReorderPlaceholder,
                hint: questionListReorderHint,
                end: saveQuestionOrder
            });

            $('.sn-survey-section-inner').find('input[type="text"]').on('focus', function () {
                $(this).select();
            });
        };

        survey.renderSurveyQuestion = function ($section, question, validator) {
            var type = question.Type;
            if (type === 'ShortText')
                type = 'ShortAnswer';
            else if (type === 'Number')
                type = 'Number';
            else if (type === 'LongText')
                type = 'Paragraph';
            else if (type === 'Boolean')
                type = 'Switch';
            else if (type === 'Reference')
                type = 'Upload';

            if (view === 'edit' || view === 'new') {
                survey.addQuestionToSection(
                    $section.closest('.sn-survey-section').attr('id'), type, question);

                var $question = $('#' + question.Id);
                var $menu = $question.find('.sn-survey-custommenu');
                var $editorDiv = $question.find('.sn-survey-question-edit');

                for (var i = 0; i < $menu.find('li').length; i++) {
                    var field = $($menu.find('li')[i]).attr('data-field');
                    if (typeof question[field] === 'string' && question[field].length > 0) {
                        var index = $($menu.find('li')[i]).index() + 1;
                        $($menu.find('li')[i]).trigger("click");
                        $editorDiv.find('input').eq(index).val(question[field]);
                    }
                        //load validation settings
                    else if (typeof question[field] === 'object' && field === 'Validation') {
                        var validation = question[field];
                        if ((typeof validation.Value.value !== 'undefined' &&
                                    validation.Value.value !== '') ||
                            typeof validation.Rule.regex !== 'undefined' ||
                            validation.Rule.value === 'WholeNumber') {
                            $($menu.find('li')[i]).trigger("click");

                            if (typeof validation.Type !== 'undefined') {
                                var validationType = validation.Type.value;
                                if (validationType = 'ShortText' &&
                                        typeof validation.Rule.regexRule !== 'undefined')
                                    validationType = 'regexp';
                                if (typeof validationType !== 'undefined' &&
                                        typeof validation.Rule.cascadeFrom === 'undefined') {
                                    $editorDiv.find('#Type option[data-snfield="' + validationType + '"]')
                                              .attr("selected", true)
                                              .trigger('change');
                                    $editorDiv.find('#Type').trigger('change');
                                }
                                else if (typeof validation.Rule.cascadeFrom !== 'undefined') {
                                    for (var k = 0; k < $editorDiv.find('#Type option').length; k++) {
                                        if (validationType === 'regexp') {
                                            $($editorDiv.find('#Type option[value="regexp"]'))
                                                        .attr("selected", true)
                                                        .trigger('change');
                                        }
                                        else if ($($editorDiv.find('#Type option')[k]).val().indexOf(validation.Rule.valueType) === 0)
                                            $($editorDiv.find('#Type option')[k]).attr("selected", true).trigger('change');
                                    }
                                    $editorDiv.find('#Type').trigger('change');
                                }

                            }
                            var validationRule = validation.Rule.value;
                            if (typeof validationRule !== 'undefined') {
                                if (validationRule === 'Regex') {
                                    $editorDiv.find('#Rule option[value="' + validation.Rule.regexRule.toLowerCase() + '"]').attr('selected', true);
                                    $editorDiv.find('#Rule').trigger('change');
                                }
                                else {
                                    var rule = getValidationRuleByName(validationRule, type);
                                    if (typeof rule !== 'undefined')
                                        $editorDiv.find('#Rule option[value="' + rule + '"]').attr('selected', true);
                                    else
                                        $editorDiv.find('#Rule option[value="' + validationRule.toLowerCase() + '"]').attr('selected', true);
                                    $editorDiv.find('#Rule').trigger('change');
                                }
                            }
                            if (validation.ErrorMessage.value !== '')
                                $editorDiv.find('#ErrorMessage').val(decodeString(question[field].ErrorMessage.value));
                            if (typeof validation.Value.value === 'string')
                                $editorDiv.find('#Value').val(decodeString(validation.Value.value));
                            else
                                for (var value in validation.Value.value) {
                                    $editorDiv.find('#' + value).val(decodeString(validation.Value.value[value]));
                                }
                        }
                        else {
                            $editorDiv.find('#Type option:first').attr("selected", true).trigger('change');
                            $editorDiv.find('#Type').trigger('change');
                        }
                    }
                }
                //load saved settings
                if (typeof question.Settings !== 'undefined')
                    if (typeof question.Options !== 'undefined') {
                        //SN.Fields[question.Control].editor.schema.fields.Settings.render($question);
                        for (var x = 0; x < question.Options.length; x++) {
                            var listItem = { title: question.Options[x].title, index: x, jumpto: question.Options[x].nextSectionIndex };
                            if (question.Other && x === question.Options.length - 1)
                                listItem.other = true;
                            var item = SN.Fields[question.Control].editor.schema.fields.Settings.ListItem.render(
                                '<li class="option-row option-row-other"><div><input type="' + question.Control.toLowerCase() + '" /><label class="option-title">#=title#</label><span class="fa sn-icon sn-icon-remove"></span></div><div class="option-jumptosection"><select><option value="">' + SN.Resources.SurveyList["GoToQuestion-Menu"] + '</option></select></div></li>',
                                listItem);
                            if (view === 'edit') {
                                if (typeof listItem.other !== 'undefined' && listItem.other)
                                    item = SN.Fields[question.Control].editor.schema.fields.Settings.ListItem.render(SN.Fields[question.Control].editor.schema.fields.Settings.OtherValue.template, listItem);
                                else
                                    item = SN.Fields[question.Control].editor.schema.fields.Settings.ListItem.render(SN.Fields[question.Control].editor.schema.fields.Settings.ListItem.template, listItem);
                            }
                            $question.find('.sn-survey-choicequestion-options').append(item);
                        }
                        if (typeof SN.Fields[question.Control].editor.schema.fields.Settings.render === 'function')
                            SN.Fields[question.Control].editor.schema.fields.Settings.render($question, view);
                    }
                    else {
                        for (var prop in question.Settings)
                            if (typeof question.Settings[prop] === 'object') {
                                $question.find('.sn-survey-question-inner input#' + prop).val(question.Settings[prop].value);
                            }
                    }


                $menu.find('ul').removeClass('visible');
            }
            else {
                if (typeof question.Control !== 'undefined')
                    type = question.Control;
                var f = SN.Fields[type];
                var fillTemplate = f.fill.template;

                var template = kendo.template(fillTemplate);
                var templatedQuestion = template(question);

                var $q = $(templatedQuestion).appendTo($section);
                var t = question.Type;
                if (typeof question.Control !== 'undefined')
                    t = question.Control;
                $q.addClass('sn-question').attr('data-fieldtype', t).attr('data-qid', question.Id);
                var $input = $q.find('input');
                if ($input.length === 0)
                    $input = $q.find('textarea');

                if (type === 'WholeNumber' || type === 'Number')
                    $input.attr('type', 'number');
                else if (type === 'Boolean' || type === 'Switch')
                    $input.attr('type', 'checkbox');
                else if (type === 'Upload')
                    $input.attr('type', 'file');
                else
                    $input.attr('type', 'text');
                if (type === 'Checkbox')
                    $input = $q.find('.sn-answer');
                if (question.Required && question.Type !== 'Reference' && question.Type !== 'Choice') {
                    $input.attr({
                        'required': '',
                        'validationMessage': SN.Resources.SurveyList["Required"]
                    });
                    $q.addClass('sn-survey-question-required');
                }
                else if (question.Required && (question.Type === 'Reference' || question.Type === 'Grid')) {
                    $input.attr({
                        'custom-required': '',
                        'validationMessage': SN.Resources.SurveyList["Required"]
                    });
                    $q.addClass('sn-survey-question-required');
                }
                if ($input.length === 0)
                    $input = $q;
                if (typeof question.Validation !== 'undefined')
                    bindValidation($input, question, question.Type.toLowerCase());
                if (question.Required)
                    $input.attr('data-validate', '');

                var renderingFunction = f.fill.render;
                if (typeof renderingFunction !== 'undefined')
                    renderingFunction(question.Id, '', question, surveyPath);

                $input.on('input, keyup', function () {
                    validator.validateInput($(this));
                });
            }
        };

        survey.initMenu = function () {
            var $menu = $(templates["menu.html"]).appendTo();
        };

        survey.initProgressbar = function () {
            var $progressBar = $('<div class="sn-survey-progressbar"></div>').appendTo($form);
            var max = structureJSON.Sections.length - 1;
            if (intro.length === 0)
                max -= 1;
            kendoProgressBar = $progressBar.kendoProgressBar({
                min: 0,
                max: max,
                value: 1,
                change: onProgressChange,
                showStatus: true,
                type: "percent"
            }).data("kendoProgressBar");
        };

        survey.toggleSection = function (id) {
            var $section = $('.sn-survey-section#' + id);
            var $inner = $section.find('.sn-survey-section-inner');
            var $button = $section.find('.sn-icon-toggle');
            if ($button.hasClass('fa-angle-down')) {
                $button.removeClass('fa-angle-down');
                $button.addClass('fa-angle-up');
                $inner.slideDown();
            }
            else {
                $button.removeClass('fa-angle-up');
                $button.addClass('fa-angle-down');
                $inner.slideUp();
            }
        };

        survey.deleteSection = function (id, callback, reorder) {
            var section = getSectionById(id);
            if (typeof section.questions !== 'undefined' && section.questions.length > 0 && !reorder) {
                survey.deleteQuestionPhysically(section, section.questions[0].Id, function () {
                    for (var i = structureJSON.Sections.length - 1; i--;) {
                        if (structureJSON.Sections[i].id === id) {
                            structureJSON.Sections.splice(i, 1);
                            var ind = i;
                        }
                    }
                    if (typeof reorder === 'undefined' || !reorder) {
                        $('.sn-survey-section#' + id).remove();
                        reindexJSONData(function () {
                            refreshSectionTitlesAndJumpToSelects();
                        });
                    }
                    if (typeof callback !== 'undefined' && typeof callback === 'function')
                        callback();
                    overlayManager.hideOverlay();
                }, section.questions.length, 0);
            }
            else if (section.questions.length === 0 && !reorder) {
                for (var i = structureJSON.Sections.length - 1; i--;) {
                    if (structureJSON.Sections[i].id === id) {
                        structureJSON.Sections.splice(i, 1);
                        var ind = i;
                        $('.sn-survey-section#' + id).remove();
                    }
                }
                if (typeof reorder === 'undefined' || !reorder) {
                    $('.sn-survey-section#' + id).remove();
                    reindexJSONData(function () {
                        refreshSectionTitlesAndJumpToSelects();
                    });
                }
                if (typeof callback !== 'undefined' && typeof callback === 'function')
                    callback();
                overlayManager.hideOverlay();
            }
        };

        survey.copySection = function (section, index) {
            var options = {
                title: section.title + ' - ' + SN.Resources.SurveyList["Copy"],
                id: createGuid(),
                index: index || Number(section.index) + 1
            };
            var sc = new Section(options);
            var s = pushSectionToTheJson(sc, options.index - 1);
            survey.renderSurveySection(s, section.id);
            reindexJSONData(function () {
                refreshSectionTitlesAndJumpToSelects();
                if (typeof section.questions !== 'undefined' && section.questions.length > 0)
                    loadQuestions($('#' + options.id).find('.sn-survey-questions'), section.questions);
            });
            survey.selectSection(options.id);
        };

        survey.addNewSection = function () {
            var lastSection = getLastSection();
            var newId = createGuid();
            var options = {
                id: newId,
                index: lastSection.index + 2
            };
            var id = lastSection.id;

            var section = new Section(options);

            var index = lastSection.index;

            var sc = pushSectionToTheJson(section, index);

            survey.renderSurveySection(sc, id);
            reindexJSONData(function () {
                refreshSectionTitlesAndJumpToSelects();
            });
            survey.selectSection(newId);
        };

        survey.reAddSection = function (section, index) {

            var sc = pushSectionToTheJson(section, index);
            reindexJSONData(function () {
                refreshSectionTitlesAndJumpToSelects();
            });
        };

        survey.selectSection = function (id) {
            $('.sn-survey-section').removeClass('selected');
            $('.sn-survey-section#' + id).addClass('selected');
            survey.scrollToSection(id);
        };

        survey.goToSection = function ($currentSection, next) {
            var $section;
            if (typeof next === 'undefined')
                $section = $currentSection;
            else if (next)
                $section = $currentSection.next();
            else
                $section = $currentSection.prev();
            $section.siblings('.sn-survey-section').addClass('hidden');
            $section.removeClass('hidden');

            var section = getSectionById($section.attr('id'));
            if (structureJSON.ProgressBar)
                refreshProgressBar(section);
        };

        survey.scrollToSection = function (id) {
            $('html, body').animate({
                scrollTop: $("#" + id).offset().top - 50
            }, 700);
        };

        survey.addQuestionToSection = function (sectionId, questionType, q) {
            if (questionType === 'Choice')
                questionType = q.Control;

            var question = getFieldTypeByName(questionType);
            if (questionType)
                if (typeof question === 'undefined')
                    question = SN.Fields[questionType];
            var questionModel = q;
            var settings;
            if (typeof q === 'undefined') {
                questionModel = createViewModel(question);
                settings = question.editor.schema.fields.Settings;
            }
            else if (typeof q !== 'undefined' && questionType !== 'Grid')
                settings = q.Settings;

            var template = kendo.template(question.editor.template);
            var templatedQuestion = template(questionModel);

            var $question = $(templatedQuestion).appendTo($('#' + sectionId).find('.sn-survey-questions'));

            if (typeof q !== 'undefined' && q.Required)
                $question.addClass('sn-survey-question-required');

            buildQuestionHeader($question, questionModel, question.editor.menu, question, q !== 'undefined');

            var $questionInner = $question.find('.sn-survey-question-inner');
            questionModel.Settings = {
            };
            if (typeof settings !== 'undefined') {
                for (var obj in settings) {
                    if (typeof settings[obj] !== 'string' && typeof settings[obj] !== 'function')
                        questionModel.Settings[obj] = $.extend(true, {}, settings[obj]);
                }

                for (var i = 0; i < $questionInner.find('input').length; i++) {
                    var input = $questionInner.find('input')[i];
                    var name = input.id;
                    var value = input.value;
                    if ($(input).parent('td').length === 0 && $(input).parent('th').length === 0)
                        questionModel.Settings[name].value = value;
                }
            }


            var renderingFunction = question.fill.render;
            if (renderingFunction === 'undefined')
                renderingFunction = SN.Fields[questionType].fill.render;
            var validationFunction;
            if (typeof question.editor.schema.fields.Settings !== 'undefined') {
                validationFunction = question.editor.schema.fields.Settings.validation;
                if (validationFunction === 'undefined')
                    validationFunction = SN.Fields[questionType].editor.schema.fields.Settings.validation;
            }

            var timeoutId;
            $question.find('input').on('input', function () {
                if (!loadingPreview)
                    refreshPreview($question.attr('id'), getFillTemplateByName(questionType), questionModel, renderingFunction, validationFunction);
                var $this = $(this);
                var id = $this.closest('.sn-survey-question').attr('id');
                var sectionId = $this.closest('.sn-survey-section').attr('id');
                var section = getSectionById(sectionId);
                question = getQuestionById(section, id);
                clearTimeout(timeoutId);
                timeoutId = setTimeout(function () {
                    if ($this.hasClass('title') && $this.val().length === 0) {
                        question.title = SN.Resources.SurveyList["UntitledQuestion"];
                        $this.val(SN.Resources.SurveyList["UntitledQuestion"]);
                        if (!loadingPreview)
                            refreshPreview($question.attr('id'), getFillTemplateByName(questionType), question, renderingFunction, validationFunction);
                    }
                    survey.modifyQuestion(question, sectionId, $question);
                }, 500);
            });

            if (typeof questionModel.Validation !== 'undefined')
                buildValidationRow($question.find('.validation'), questionModel.Validation, question, questionModel);

            if (typeof q === 'undefined') {


                if (questionType === 'date' && typeof q === 'undefined')
                    questionModel.Validation.Rule.valueType = 'date';
                survey.saveQuestion(sectionId, questionModel,
                    function () {
                        survey.selectQuestion(questionModel.Id, true);
                        $('#' + questionModel.Id + ' .validation').find('select').first().trigger('change');
                    });
            }

            buildQuestionInner($question, question, questionModel);

            var $preview = $('<div class="sn-survey-question-preview"></div>').appendTo($question);
            if (typeof question.fill.template !== 'undefined') {
                var previewTemplate = kendo.template(question.fill.template);
                var templatedPreview = previewTemplate(questionModel);
                $preview.append(templatedPreview);
                $preview.find('input').attr('disabled', 'disabled');

                if (typeof renderingFunction !== 'undefined' && view === 'add')
                    renderingFunction(questionModel.Id, 'editor', question);
                else if (typeof renderingFunction !== 'undefined' && view === 'edit')
                    renderingFunction(questionModel.Id, 'editor', questionModel);

            }
            $preview.before('<span class="fa sn-icon sn-icon-' + question.icon + '"></span>');

            $question.on('mousedown', function (e) {
                if ($(e.target).closest('.sn-survey-question-edit').length || $(e.target).closest('.sn-survey-question-inner').length || $(e.target).closest('.sn-survey-custommenu').length)
                    return;
                survey.selectQuestion(questionModel.Id);
            });

            var $deleteButton = $question.find('.sn-icon-delete');
            $deleteButton.on('click', function () {
                var $this = $(this);
                var sid = $this.closest('.sn-survey-section').attr('id');
                var qid = $this.closest('.sn-survey-question').attr('id');
                deleteQuestionConfirmation($this.closest('.sn-survey-question').find('input[type="text"]').first().val(), sid, qid, survey.deleteQuestion);
            });


            if (view === 'edit' && typeof q === 'undefined')
                $question.attr('data-new', true);


            $question.find('input[type="text"]').on('focus', function () {
                $(this).select();
            });
        };

        survey.selectQuestion = function (id, add) {
            var $question = $('.sn-survey-question#' + id);
            $('.sn-survey-question').removeClass('selected');
            $question.addClass('selected');
            if ((typeof add === 'undefined' || !add) && $question.find('.validation').length > 0) {
                var selected = $question.find('select.validation-dropdown').find('option:selected').val();
                var section = getSectionById($question.closest('.sn-survey-section').attr('id'));
                var question = getQuestionById(section, id);
                var type = question.Type;
                switch (type) {
                    case 'LongText':
                        type = 'Paragraph';
                        break;
                    case 'ShortText':
                        type = 'ShortAnswer';
                        break;
                    default:
                        break;
                }
                validationItem = getValidationItem(selected, SN.Fields[type].editor.schema.validation.fields["Type"]);
                if ($question.find('select.cascaded-select').length > 0 && add)
                    triggerCascadedTextbox($question.find('select.cascaded-select'));
            }
        };

        survey.saveQuestion = function (sectionId, questionModel, callback) {
            var section = getSectionById(sectionId);
            section.questions.push(questionModel);
            saveDataToTextBox();

            if (typeof callback !== 'undefined' && typeof callback === 'function')
                callback();
        };

        survey.modifyQuestion = function (model, sectionId, $question) {
            var $section = $('#' + sectionId);
            model.Hint = $question.find('.hint').val();
            model.PlaceHolder = $question.find('.placeholder').val();
            model.Title = $question.find('.title').val();
            var section = getSectionById(sectionId);
            var questionIndex = getQuestionIndexById(section, model.Id);
            section.questions[questionIndex] = model;
            $question.attr('data-edited', true);
            saveDataToTextBox();
        };

        survey.deleteQuestion = function (sectionId, questionId) {
            var section = getSectionById(sectionId);

            if (view === 'new' || (view === 'edit' && $('#' + questionId).attr('data-new') === 'true')) {
                var questionIndex = getQuestionIndexById(section, questionId);
                section.questions.splice(questionIndex, 1);
                saveDataToTextBox(function () {
                    $('.sn-survey-question#' + questionId).remove();
                });
                overlayManager.hideOverlay();
            }
            else {
                survey.deleteQuestionPhysically(section, questionId, function () {
                    var questionIndex = getQuestionIndexById(section, questionId);
                    section.questions.splice(questionIndex, 1);
                    saveDataToTextBox(function () {
                        $('.sn-survey-question#' + questionId).remove();
                    });
                    overlayManager.hideOverlay();
                });
            }
        };

        survey.saveSurvey = function () {
            saveDefaultFields(saveSettings);
        };

        survey.modifySurvey = function () {
            var modifiedSections = survey.getModifiedSections();
            var modifiedQuestions = survey.getModifiedQuestions();
            var s = {};
            s.path = surveyPath;
            s.contentItem = {};
            s.contentItem['RawJson'] = $('.sn-ctrl-rawjson').val();
            s.success = function () {
                if (modifiedSections.length > 0)
                    modifySurveyFields(modifiedSections, function () {
                        if (modifiedQuestions.length > 0)
                            recursiveQuestionModify(modifiedQuestions, 0);
                        else
                            window.location.href = surveyPath;
                    });
                else {
                    if (modifiedQuestions.length > 0)
                        recursiveQuestionModify(modifiedQuestions, 0);
                    else
                        window.location.href = surveyPath;
                }
                var name = odata.getNameFromPath(surveyPath);
                var newFields = getNewlyAddedQuestions();
                if (newFields.length > 0)
                    saveNewFields(name, newFields);
            };
            odata.saveContent(s);

        };

        survey.getModifiedQuestions = function () {
            var questions = [];
            var questionLength = $('.sn-survey-question[data-edited="true"]').length;
            if (questionLength > 0)
                for (var i = 0; i < questionLength; i++) {
                    questions.push(survey.getQuestionByElement($($('.sn-survey-question[data-edited="true"]')[i])));
                }
            return questions;
        };

        survey.getModifiedSections = function () {
            var sections = [];
            for (var i = 0; i < $('.sn-survey-section[data-edited="true"]').length; i++) {
                var $section = $($('.sn-survey-section[data-edited="true"]')[i]);
                if ($section.hasClass('sn-survey-settings') || $section.is('#intro, #outro')) {
                    var section = survey.getSectionByElement($section);
                    if (typeof section !== 'undefined')
                        sections.push(section);
                    else
                        sections.push(new Section({ title: $section.find('#textbox-displayname').val(), description: $section.find('.sn-textarea-paragraph').val() }));
                }
            }
            return sections;
        };

        survey.getSections = function () {
            return structureJSON.Sections;
        };

        survey.getSectionById = function (id) {
            return getSectionById(id);
        };

        survey.getQuestionById = function (section, id) {
            return getQuestionById(section, id);
        };

        survey.getSectionByElement = function ($elem) {
            var sectionId = $elem.closest('.sn-survey-section').attr('id');
            return survey.getSectionById(sectionId);
        };

        survey.getQuestionByElement = function ($elem) {
            var section = survey.getSectionByElement($elem);
            var questionId = $elem.closest('.sn-survey-question').attr('id');
            return getQuestionById(section, questionId);
        };

        survey.saveDataToTextBox = function () {
            saveDataToTextBox();
        };

        survey.refreshPreview = function (id, template, model, renderingFunction) {
            refreshPreview(id, template, model, renderingFunction);
        };

        survey.encodeString = function (string) {
            return encodeString(string);
        };

        survey.deleteQuestionPhysically = function (section, questionId, callback, arrayLength, index) {
            var question = survey.getQuestionById(section, questionId);
            var fieldName = question.Type + question.Id;
            var path = surveyPath + '/' + fieldName;

            odata.deleteField({
                path: path
            }).done(function () {
                if (typeof arrayLength !== 'undefined' && (arrayLength - 1) > index)
                    survey.deleteQuestionPhysically(section, section.questions[index + 1].Id, callback, arrayLength, index + 1);
                else {
                    if (typeof callback === 'function')
                        callback();
                }
            }).error(function (xhr, status, text) {
                var response = $.parseJSON(xhr.responseText);
                if (response.error.exceptiontype === 'InvalidContentActionException') {
                    if (typeof callback === 'function')
                        callback();
                }
                else {
                    overlayManager.hideOverlay();
                    var $overlay = overlayManager.showOverlay({
                        text: '<span class="fa fa-warning"></span>' + response.error.message.value,
                        cssClass: "popup-error",
                        appendCloseButton: true
                    });
                }
            });
        };

        survey.getValidator = function () {
            return validator;
        };
        survey.initSettings = function () {
            if (settings.length > 0) {
                var $settingsButton = $('<span class="sn-survey-settingsbutton fa fa-cog">' + SN.Resources.SurveyList["SettingsButtonText"] + '</span>').appendTo($form);

                var positionLeft, positionTop;

                $(document).ready(SettingsButtonPositioning);
                $(window).resize(SettingsButtonPositioning);

                var $settingsWindow = survey.initSettingsWindow();

                $settingsButton.on('click', function () {
                    fillSettingsWindow();
                    $settingsWindow.data("kendoWindow").open();
                });
            }

            function SettingsButtonPositioning() {
                positionLeft = $form.offset().left + $form.width() + 25;
                positionTop = $form.offset().top - 60;
                $settingsButton.css({
                    'top': positionTop,
                    'left': positionLeft
                });
            }
        };

        survey.initSettingsWindow = function () {
            var $settingsWindow = $('<div id="settingsWindow" style="display: none"></div>').appendTo($form);
            var $tabStrip = $('<div class="settingTabStrip"></div>').appendTo($settingsWindow);
            var $ul = $('<ul></ul>').appendTo($tabStrip);
            for (var i = 0; i < settings.length; i++) {
                var $li = $('<li title="' + SN.Resources.SurveyList[settings[i].name] + '">' + SN.Resources.SurveyList[settings[i].name] + '</li>').appendTo($ul);
                if (i === 0)
                    $li.addClass('k-state-active');
                var $div = $('<div id="' + settings[i].name + '"></div>').appendTo($tabStrip);
                for (var j = 0; j < settings[i].items.length; j++) {
                    if (settings[i].items[j].type === 'boolean') {
                        SN.Controls.Switch.render($div, {
                            label: SN.Resources.SurveyList[settings[i].items[j].name],
                            value: structureJSON.settings[settings[i].items[j].name] || settings[i].items[j].value,
                            id: settings[i].items[j].name,
                            key: settings[i].items[j].name,
                            info: SN.Resources.SurveyList[settings[i].items[j].name + '-Description'],
                            data: structureJSON.settings,
                            save: setBooleanValue
                        });
                    }
                    else if (settings[i].items[j].type === 'datetime') {
                        SN.Controls.DateTime.render($div, {
                            label: SN.Resources.SurveyList[settings[i].items[j].name],
                            value: decodeString(structureJSON.settings[settings[i].items[j].name]) || settings[i].items[j].value,
                            id: settings[i].items[j].name,
                            key: settings[i].items[j].name,
                            info: SN.Resources.SurveyList[settings[i].items[j].name + '-Description'],
                            data: structureJSON.settings,
                            save: setStringValue
                        });
                    }
                    else if (settings[i].items[j].type === 'longtext') {
                        SN.Controls.Textarea.render($div, {
                            label: SN.Resources.SurveyList[settings[i].items[j].name],
                            value: decodeString(structureJSON.settings[settings[i].items[j].name]) || settings[i].items[j].value,
                            id: settings[i].items[j].name,
                            key: settings[i].items[j].name,
                            info: SN.Resources.SurveyList[settings[i].items[j].name + '-Description'],
                            rows: 3,
                            data: structureJSON.settings,
                            save: setStringValue
                        });
                    }
                    else if (settings[i].items[j].type === 'richtext') {
                        SN.Controls.Paragraph.render($div, {
                            label: SN.Resources.SurveyList[settings[i].items[j].name],
                            value: structureJSON.settings[settings[i].items[j].name] || settings[i].items[j].value,
                            id: settings[i].items[j].name,
                            key: settings[i].items[j].name,
                            mode: 'edit',
                            isRichText: true,
                            info: SN.Resources.SurveyList[settings[i].items[j].name + '-Description'],
                            data: structureJSON.settings,
                            save: setStringValue
                        });
                    }
                    else if (settings[i].items[j].type === 'emailfield') {
                        var options = getEmailFieldOptions();
                        SN.Controls.String.render($div, {
                            label: SN.Resources.SurveyList[settings[i].items[j].name],
                            value: structureJSON.settings[settings[i].items[j].name] || settings[i].items[j].value,
                            id: settings[i].items[j].name,
                            key: settings[i].items[j].name,
                            info: SN.Resources.SurveyList[settings[i].items[j].name + '-Description'],
                            data: structureJSON.settings
                        });
                        $('input[name="' + settings[i].items[j].name + '"]').kendoDropDownList({
                            dataTextField: "title",
                            dataValueField: "name",
                            dataSource: options,
                            value: structureJSON.settings[settings[i].items[j].name] || 0,
                            change: function (e) {
                                structureJSON.settings[$('#textbox-EmailField').attr('name')] = this.value();
                                saveDataToTextBox(function () {
                                    refreshSectionTitlesAndJumpToSelects();
                                });
                            }
                        });
                    }
                    else {
                        SN.Controls.String.render($div, {
                            label: SN.Resources.SurveyList[settings[i].items[j].name],
                            value: decodeString(structureJSON.settings[settings[i].items[j].name]) || settings[i].items[j].value,
                            id: settings[i].items[j].name,
                            key: settings[i].items[j].name,
                            info: SN.Resources.SurveyList[settings[i].items[j].name + '-Description'],
                            data: structureJSON.settings,
                            save: setStringValue
                        });
                    }

                    settingsToSave[settings[i].items[j].name] = settings[i].items[j].value;
                }

            }

            $tabStrip.kendoTabStrip();

            var $buttonRow = $('<div class="sn-panel sn-buttons"></div>').appendTo($settingsWindow);
            var $settingsSaveButton = $('<div id="settingsSave" class="sn-window-button sn-window-submit">' + SN.Resources.SurveyList["Save"] + '</div>').appendTo($buttonRow);
            var $settingsCancelButton = $('<div id="settingsCancel" class="sn-window-button sn-window-cancel">' + SN.Resources.SurveyList["Cancel"] + '</div>').appendTo($buttonRow);

            $settingsSaveButton.on('click', function () {
                $settingsWindow.find('.sn-formrow input').each(function () {
                    var $this = $(this);
                    if (typeof $this.attr('name') !== 'undefined') {
                        if (!$this.is(':checkbox'))
                            settingsToSave[$this.attr('name')] = $this.val();
                        else {
                            if ($this.is(':checked'))
                                settingsToSave[$this.attr('name')] = true;
                            else
                                settingsToSave[$this.attr('name')] = false;
                        }
                    }
                });
                $settingsWindow.data("kendoWindow").close();
            });
            $settingsCancelButton.on('click', function () {
                $settingsWindow.data("kendoWindow").close();
            });

            var left = ($(window).width() - 950) / 2;
            $settingsWindow.kendoWindow({
                width: 950,
                visible: false,
                modal: true,
                position: {
                    top: 100,
                    left: left
                },
                activate: function () {
                    $settingsWindow.find('input').each(function () {
                        var $this = $(this);
                        var value = $this.attr('data-value');
                        if ($this.hasClass('datepicker')) {
                            var datePicker = $this.data('kendoDateTimePicker');
                            if ($this.val() === '')
                                datePicker.value(value);
                        }
                        else if ($this.hasClass('shorttext')) {
                            if ($this.val() === '')
                                $this.val(value);
                        }
                    });
                }
            });
            return $settingsWindow;
        };

        function getEmailFieldOptions() {
            var options = [{ name: 'Email', title: SN.Resources.SurveyList["Email"] }];
            for (var i = 0; i < $('.sn-survey-question').length; i++) {
                var fieldTitle = $($('.sn-survey-question')[i]).find('.title').val();
                var question = survey.getQuestionByElement($($('.sn-survey-question')[i]));
                var fieldName = question.Type + question.Id;
                options.push({ name: fieldName, title: fieldTitle });
            }
            return options;
        }

        function fillSettingsWindow() {
            for (var prop in settingsToSave) {
                if (prop === 'EmailField') {
                    var options = getEmailFieldOptions();
                    $('#settingsWindow').find('input[name="' + prop + '"]').data("kendoDropDownList").dataSource.data(options);
                }
                else
                    $('#settingsWindow').find('input[name="' + prop + '"]').val(settingsToSave[prop]);
            }
        }

        function loadSections() {
            var $section, $nextButton, $prevButton, $submitButton, $sectionFooter, $sectionInner;
            var buttonTexts = {
                next: SN.Resources.SurveyList["NextSection"],
                previous: SN.Resources.SurveyList["PreviousSection"],
                submit: SN.Resources.SurveyList["Submit"]
            };

            var nextKendoTemplate = kendo.template(templates["nextButton.html"]),
                prevKendoTemplate = kendo.template(templates["prevButton.html"]),
                submitKendoTemplate = kendo.template(templates["submitButton.html"]);

            var templatedNext = nextKendoTemplate(buttonTexts),
                templatedPrev = prevKendoTemplate(buttonTexts),
                templatedSubmit = submitKendoTemplate(buttonTexts);


            if (intro && intro.length > 0) {
                $section = $(templates["section.html"]).appendTo($form);
                $section.attr('id', 'intro');
                var $sectionInner = $section.find('.sn-survey-section-inner');
                SN.Controls.Paragraph.render($sectionInner, {
                    label: SN.Resources.SurveyList["Intro-DisplayName"],
                    info: '',
                    mode: 'browse',
                    value: intro
                });
                if (structureJSON.ProgressBar) {
                    $sectionFooter = $(templates["sectionButtonRow.html"]).appendTo($section);
                    $nextButton = $(templatedNext).appendTo($sectionFooter);
                }
            }
            for (var i = 1; i < structureJSON.Sections.length - 1; i++) {
                var section = structureJSON.Sections[i];

                $section = $(templates["section.html"]).appendTo($form);
                $section.attr({
                    'id': section.id,
                    'data-index': section.index
                });
                if (structureJSON.ProgressBar) {
                    $sectionFooter = $(templates["sectionButtonRow.html"]).appendTo($section);
                }
                $sectionInner = $section.find('.sn-survey-section-inner');
                SN.Controls.H2.render($sectionInner, {
                    mode: 'browse',
                    title: decodeString(section.title),
                    hint: decodeString(section.hint)
                });
                if (typeof section.description !== 'undefined' && section.description.length > 0)
                    SN.Controls.Paragraph.render($sectionInner, {
                        mode: 'browse',
                        value: decodeString(section.description)
                    });

                var $sectionQuestions = $('<div class="sn-survey-section-questions"></div>').appendTo($sectionInner);

                if (i === structureJSON.Sections.length - 2) {
                    if (!structureJSON.ProgressBar) {
                        $sectionFooter = $(templates["sectionButtonRow.html"]).appendTo($section);
                    }
                    if ((i === 1 && typeof intro !== 'undefined' && intro.length > 0) && structureJSON.ProgressBar) {
                        $prevButton = $(templatedPrev).appendTo($sectionFooter);
                    }
                    else if (i > 1 && structureJSON.ProgressBar)
                        $prevButton = $(templatedPrev).appendTo($sectionFooter);
                    $submitButton = $(templatedSubmit).appendTo($sectionFooter);
                }
                else {
                    if (structureJSON.ProgressBar) {
                        if (i > 1 || (i === 1 && intro.length > 0))
                            $prevButton = $(templatedPrev).appendTo($sectionFooter);
                        $nextButton = $(templatedNext).appendTo($sectionFooter);
                    }
                }
                if (structureJSON.ProgressBar && intro.length > 0)
                    $section.addClass('hidden');
                else if (structureJSON.ProgressBar && i !== 1)
                    $section.addClass('hidden');




                if (section.questions.length > 0) {
                    //var $status = $('<div class="sn-survey-section-status"></div>').appendTo($sectionQuestions);
                    loadQuestions($sectionQuestions, section.questions);
                }

            }

            var validatable = createValidationObj();

            if (outro) {
                $section = $(templates["section.html"]).appendTo($form);
                $section.attr('id', 'outro');
                $sectionInner = $section.find('.sn-survey-section-inner');
                SN.Controls.Paragraph.render($sectionInner, {
                    label: SN.Resources.SurveyList["Outro-DisplayName"],
                    info: '',
                    mode: 'browse',
                    value: outro
                });
                $section.addClass('hidden');
            }


            survey.$el.find('.sn-next-button').on('click', function () {
                var $section = $(this).closest('.sn-survey-section');
                var valid = true;
                for (var i = 0; i < $section.find('input').length; i++) {
                    if (!validator.validateInput($section.find('input')[i]))
                        valid = false;
                }

                var id = $section.attr('id');
                var section = survey.getSectionById(id);
                var next;
                for (var j = 0; j < $section.find('.sn-question').length; j++) {
                    var $question = $section.find('.sn-question').eq(j);
                    var questionId = $question.attr('data-qid');
                    var question = getQuestionById(section, questionId);
                    if (typeof question !== 'undefined' && (typeof question.jump !== 'undefined' || typeof question.Jump !== 'undefined')) {
                        var goto = $question.find('input:checked');
                        next = Number(goto.parent().attr('data-next'));
                        if (goto.length === 0) {
                            goto = $question.find('option:selected');
                            next = Number($section.attr('data-index')) + 1;
                        }
                    }
                    else
                        next = Number($section.attr('data-index')) + 1;
                }
                if (typeof next !== 'undefined' && next > 0)
                    $section = $('.sn-survey-section[data-index="' + next + '"]');
                if (valid) {
                    if (next === structureJSON.Sections.length - 1)
                        $('.sn-submit-button').trigger('click');
                    else {
                        if (typeof next !== 'undefined')
                            survey.goToSection($section);
                        else
                            survey.goToSection($section, true);
                    }
                }
            });
            survey.$el.find('.sn-prev-button').on('click', function () {
                survey.goToSection($(this).closest('.sn-survey-section'), false);
            });
            survey.$el.find('.sn-submit-button').on('click', function () {
                var $that = $(this);
                var $section = $that.closest('.sn-survey-section');
                var valid = true;
                if (validateFieldsOneByOne() && valid) {
                    var saveableAnswers = getSaveableAnswers();
                    var content = {
                        path: surveyPath,
                        contentItem: saveableAnswers,
                        success: function () {
                            var outroSection = getSectionById('outro');
                            if (outroSection.afterSubmit !== 'undefined' && outroSection.afterSubmit.length > 0) {
                                var afterSubmitFunctionString = decodeString(outroSection.afterSubmit);
                                var afterSubmitFunction = new Function(afterSubmitFunctionString);
                                afterSubmitFunction();
                            }
                            else if (outroSection.landingPage !== 'undefined' && outroSection.landingPage.length > 0) {
                                window.location.href = outroSection.landingPage;
                            }
                            else if (typeof outro !== 'undefined' && outro.length > 0)
                                survey.goToSection($that.closest('.sn-survey-section'), true);
                            else
                                window.location.href = surveyPath;
                        },
                        error: function (xhr, status, text) {
                            var response = $.parseJSON(xhr.responseText);
                            overlayManager.hideOverlay();
                            var $overlay = overlayManager.showOverlay({
                                text: '<span class="fa fa-warning"></span>' + response.error.message.value,
                                cssClass: "popup-error",
                                appendCloseButton: true
                            });
                        }
                    };
                    odata.createContent(content);
                }
            });

        }

        function loadQuestions($container, q) {


            var max = q.length;
            for (var i = 0; i < max; i++) {
                survey.renderSurveyQuestion($container, q[i], validator);
            }
        }

        function refreshProgressBar(section) {
            if (typeof section !== 'undefined') {
                var index = section.index + 1;
                if (outro.length === 0)
                    index = section.index;
                kendoProgressBar.value(index);
            }
        }

        function initSectionAdding() {

            var addNewMenuTemplate = templates["addNewMenu.html"];
            var addNewMenuObj = {
                addNewSectionText: SN.Resources.SurveyList["AddNewSection"],
                addNewQuestionText: SN.Resources.SurveyList["AddNewQuestion"]
            };

            var addNewMenuKendoTemplate = kendo.template(addNewMenuTemplate);
            var templatedMenu = addNewMenuKendoTemplate(addNewMenuObj);

            // append menu to add new button
            var $button = $('<span class="sn-survey-section-add fa fa-plus">' + SN.Resources.SurveyList["AddNewElement"] + templatedMenu + '</span>').appendTo($form);

            // make variables from menu items
            var $addNewSectionButton = $('.addNewSectionButton');
            var $addNewQuestionButton = $('.addNewQuestionButton');
            var $newMenu = $('.addNewMenu');
            var $questionList = $('<ul class="sn-survey-new-question hidden"></ul>').appendTo($addNewQuestionButton);

            loadQuestionTypes($questionList);
            $questionList.find('li').on('click', function () {
                var selectedValue = $(this).attr('data-value');
                var $selectedSection = survey.getSectionByElement($('.sn-survey-section.selected'));
                survey.addQuestionToSection($selectedSection.id, selectedValue);
            });

            // make menu visible on button-click
            $button.on('click', function (e) {

                // make add-new-question visible if at least one selected section exists
                if ($('.sn-survey-section').length > 3 && $('.sn-survey-section.draggable.selected').length > 0)
                    $addNewQuestionButton.removeClass('hidden');
                else
                    $addNewQuestionButton.addClass('hidden');

                // show or hide add new options
                if (!$newMenu.hasClass('visible')) {
                    $newMenu.addClass('visible');
                }
                else {
                    if ($(e.target).hasClass('addNewMenu') || $(e.target).closest('.addNewMenu').length)
                        return;

                    $newMenu.removeClass('visible');
                }
            });


            // hide menu when body is clicked
            $('body').click(function (e) {
                if ($(e.target).hasClass('sn-survey-section-add'))
                    return;
                if ($(e.target).hasClass('addNewMenu') || $(e.target).closest('.addNewMenu').length)
                    return;
                if ($(e.target).hasClass('sn-survey-section') || $(e.target).closest('.sn-survey-section').length)
                    return;

                $newMenu.removeClass('visible');
                $questionList.addClass('hidden');
            });

            // add new section on menuitem click
            $addNewSectionButton.click(function (e) {
                survey.addNewSection();
            });

            $addNewQuestionButton.on('click', function (e) {
                if ($(e.target).closest('.sn-survey-new-question').length)
                    return;

                if ($questionList.hasClass('hidden')) {
                    $questionList.removeClass('hidden');
                } else
                    $questionList.addClass('hidden');
            });

            var positionLeft, positionTop;
            function SectionAddingPositioning() {
                positionLeft = $form.offset().left + $form.width() + 25;
                positionTop = $form.offset().top;
                $button.css({
                    'top': positionTop,
                    'left': positionLeft
                });
            }

            $(document).ready(SectionAddingPositioning);
            $(window).resize(SectionAddingPositioning);
        }

        function loadQuestionTypes($el) {
            for (var type in questionTypes) {
                var $li = $('<li data-value="' + questionTypes[type].name + '"><span class="sn-icon sn-icon-' + questionTypes[type].icon + ' fa"></span>' + questionTypes[type].title + '</li>').appendTo($el);
            }
        }

        function addCustomTypes(types) {
            for (var i = 0; i < types.length; i++)
                questionTypes[types[i].name] = types[i];
        }

        function Section(section) {
            this.id = section.id;
            this.index = section.index;
            this.title = section.title || SN.Resources.SurveyList["UntitledSection"] + (section.index - 1);
            this.description = section.description || '';
            this.hint = section.hint || '';
            this.hidden = section.hidden || false;
            this.questions = section.questions || [];
        }

        function Question(question) {
            this.id = question.id;
            this.index = question.index;
            this.required = question.required || false;
            this.type = question.type || 'string';
            this.template = question.template || '';
            this.label = question.label || 'Untitled question' + question.index + 1;
            this.hint = question.hint || null;
            this.validation = question.validation || null;
            this.schema = question.schema || null;
            this.save = question.save || null;
        }

        function QuestionType(name, text) {
            this.name = name;
            this.text = text;
        }

        function buildQuestionHeader($question, model, menu, question, old) {
            var deleteQuestion =
                {
                    deleteQuestion: SN.Resources.SurveyList["DeleteQuestion"]
                }
            var questionHeaderTemplate = kendo.template(templates["questionHeader.html"]);
            var templatedHeader = questionHeaderTemplate(deleteQuestion);
            var $questionHeader = $(templatedHeader).prependTo($question);
            var $required = $questionHeader.find('.sn-survey-required');
            if (typeof model.Required !== 'undefined') {
                var id = createGuid();
                SN.Controls.Switch.render($required, {
                    label: SN.Resources.SurveyList["Required"],
                    value: model.Required,
                    id: id,
                    save: setBooleanValue,
                    data: model,
                    key: 'Required',
                    click: function () {
                        if ($question.hasClass('sn-survey-question-required'))
                            $question.removeClass('sn-survey-question-required');
                        else
                            $question.addClass('sn-survey-question-required');
                    }
                });
            }
            if (typeof menu !== 'undefined' && menu.length > 0) {
                var $menu = $questionHeader.find('.sn-survey-custommenu ul');
                var $menubutton = $questionHeader.find('.sn-survey-custommenu');

                $menubutton.on('click', function () {

                    if (!$menu.hasClass('visible')) {
                        $menu.addClass('visible');
                    }
                });

                $('body').click(function (e) {
                    if ($(e.target).hasClass('sn-survey-custommenu'))
                        return;
                    if ($(e.target).hasClass('sn-survey-custommenu>ul'))
                        return;
                    if ($(e.target).closest('.sn-survey-custommenu>ul').length)
                        return;

                    $menu.removeClass('visible');
                });

                for (var i = 0; i < menu.length; i++) {
                    if (typeof question.editor.schema.fields[menu[i].field] !== 'undefined') {
                        var $li = $('<li class="sn-survey-custommenu-item" data-field="' + menu[i].field + '">' + menu[i].text + '</li>').appendTo($menu);
                        $li.on('click', function () {
                            var $this = $(this);
                            var field = $this.attr('data-field').toLowerCase();
                            var $element = $this.closest('.sn-survey-question').find('.' + field);
                            if ($element.hasClass('hidden')) {
                                $element.removeClass('hidden');
                                $this.attr('aria-checked', true);
                                if ($this.attr('data-field') === 'Validation') {
                                    if ($question.find('.validation .cascaded-select').length !== 0 && !old)
                                        triggerCascadedTextbox($question.find('.validation .cascaded-select'));
                                    else {
                                        var $select = $question.find('.validation .validation-dropdown');
                                        if ($select.attr('id') === 'Rule') {
                                            validationItem = question.editor.schema.validation.fields['Type'][0];
                                            triggerCascadedTextbox($select);
                                        }
                                    }
                                }
                            }
                            else {
                                $element.addClass('hidden');
                                $this.attr('aria-checked', false);
                                var f = $this.attr('data-field');
                                var q = survey.getQuestionByElement($element);
                                var qt = SN.Fields[q.Type];
                                if (typeof qt === 'undefined')
                                    qt = question;
                                if (typeof q[f] !== 'undefined' && f !== 'Validation') {
                                    $element.val('');
                                    q[f] = '';
                                    survey.refreshPreview(q.Id, qt.fill.template, q, qt.fill.render);
                                }
                                else if (typeof q[f] !== 'undefined' && f === 'Validation') {
                                    q[f] = qt.editor.schema.fields.Validation;
                                    if (typeof $element.closest('.sn-survey-question').attr('data-fieldtype') !== 'undefined' && $element.closest('.sn-survey-question').attr('data-fieldtype').length > 0) {
                                        var type = $element.closest('.sn-survey-question').attr('data-fieldtype');
                                        q.Type = type;
                                        if (type === 'ShortText')
                                            type = 'ShortAnswer';
                                        qt = SN.Fields[type];
                                    }
                                    saveDataToTextBox();
                                    rebuildValidationRow($element, q, qt);
                                }

                            }
                        });
                    }
                }
            }
        }

        function buildQuestionInner($question, question, model) {
            var $questionInner = $('<div class="sn-survey-question-inner"></div>').appendTo($question);
            var q = question;
            var settings = question.editor.schema.fields.Settings;
            if (typeof settings === 'undefined')
                return false;

            var validationFunction = settings.validation;
            var settingsTemplate = kendo.template(settings.template);
            var templatedSettings = settingsTemplate(settings);
            $questionInner.html(templatedSettings);
            if (typeof settings.render === 'function')
                settings.render($question, view);

            var timeoutId;
            $questionInner.find('input').on('input', function () {

                var $this = $(this);
                clearTimeout(timeoutId);
                timeoutId = setTimeout(function () {
                    if (typeof $this.parent().attr('role', 'gridcell') !== 'undefined') {
                        var $inner = $this.closest('.sn-survey-question-inner');
                        var sectionId = $this.closest('.sn-survey-section').attr('id');
                        var $question = $this.closest('.sn-survey-question');
                        var questionId = $question.attr('id');
                        var section = getSectionById(sectionId);
                        var question = getQuestionById(section, questionId);
                        var valid;
                        if (typeof validationFunction === 'function') {
                            var settingsArray = [];
                            for (var i = 0; i < $inner.find('input').length; i++) {
                                settingsArray.push($inner.find('input')[i].value);
                            }
                            valid = validationFunction(settingsArray);
                        }
                        if (typeof valid === 'undefined' || valid) {
                            for (var j = 0; j < $inner.find('input').length; j++) {
                                var name = $inner.find('input')[j].id;
                                var value = $inner.find('input')[j].value;
                                if (typeof question.Settings[name] === 'undefined')
                                    question.Settings[name] = {
                                    };
                                question.Settings[name].value = value;
                            }
                            $question.attr('data-edited', true);
                            saveDataToTextBox();
                            refreshPreview(model.Id, q.fill.template, model, q.fill.render, validationFunction);
                        }
                    }
                }, 500);
            });
        }

        function rebuildValidationRow($element, question, qt) {
            $element.html('');
            buildValidationRow($element, question.Validation, qt, question);
            $element.find('select').children('option:eq(0)').attr('selected', 'selected');
            $element.find('select').trigger('change');
        }

        function refreshPreview(id, template, model, renderingFunction, validationFunction) {
            var valid;
            if (typeof validationFunction === 'function') {
                var settingsArray = [];
                for (var i = 0; i < $('#' + id + ' .sn-survey-question-inner').find('input').length; i++) {
                    settingsArray.push($('#' + id + ' .sn-survey-question-inner').find('input')[i].value);
                }
                valid = validationFunction(settingsArray);
            }
            if (typeof valid === 'undefined' || valid) {
                loadingPreview = true;
                var $question = $('#' + id);
                var $previewInput = $question.find('.sn-survey-question-preview');
                model.Hint = $question.find('.hint').val();
                model.PlaceHolder = $question.find('.placeholder').val();
                model.Title = $question.find('.title').val();
                var previewTemplate = kendo.template(template);
                var templatedPreview = previewTemplate(model);
                $previewInput.html(templatedPreview);
                loadingPreview = false;
                if (model.Type === 'DateTime')
                    $previewInput.find("input").kendoDatePicker();
                if (typeof renderingFunction === 'function')
                    renderingFunction(id, 'editor', model);
            }
        }

        function saveDefaultFieldData($el, value, $input) {
            if ($el.is(':text') || !$el.is('input:text'))
                value = decodeString(value);
            $input.closest('.sn-survey-section').attr('data-edited', true);
            $el.val(value);
        }

        function modifySurveyFields(s, callback) {
            var o = {};
            o.contentItem = {};
            for (var i = 0; i < s.length; i++) {
                switch (s[i].id) {
                    case 'intro':
                        var $textarea = $('#intro').find('textarea').data("kendoEditor");
                        o.contentItem['IntroText'] = $textarea.value();
                        break;
                    case 'outro':
                        var $textarea = $('#outro').find('textarea').data("kendoEditor");
                        o.contentItem['OutroText'] = $textarea.value();
                        break;
                    default:
                        o.contentItem['DisplayName'] = s[i].title;
                        o.contentItem['Description'] = s[i].description;
                        break;
                }
            }
            o['path'] = surveyPath;
            if (typeof callback === 'function')
                o.success = callback;
            odata.saveContent(o);
        }

        function recursiveQuestionModify(modifiedQuestions, index) {
            kendo.ui.progress($form, true);
            var saveableObj = {};
            if (index < modifiedQuestions.length) {
                if (index === modifiedQuestions.length - 1)
                    saveableObj.success = function () {
                        var path = surveyPath.split('/').slice(0, -1).join('/');
                        window.location.href = path;
                    };
                else
                    saveableObj.success = function () {
                        index += 1;
                        recursiveQuestionModify(modifiedQuestions, index);
                    };
                saveableObj.error = function (xhr, status, text) {
                    var response = $.parseJSON(xhr.responseText);
                    overlayManager.hideOverlay();
                    var $overlay = overlayManager.showOverlay({
                        text: '<span class="fa fa-warning"></span>' + response.error.message.value,
                        cssClass: "popup-error",
                        appendCloseButton: true
                    });
                };

                saveableObj.contentItem = {};

                var saveableFieldArray = getSaveableFields(modifiedQuestions[index].Type, modifiedQuestions[index].Control);
                for (var i = 0; i < saveableFieldArray.length; i++) {
                    for (var prop in saveableFieldArray[i]) {
                        if (saveableFieldArray[i][prop] !== 'Validation') {
                            saveableObj.contentItem[prop] = modifiedQuestions[index][saveableFieldArray[i][prop]];
                        }
                        else {
                            var validationObject = modifiedQuestions[index][saveableFieldArray[i][prop]];
                            if (validationObject.Rule.value === prop && prop !== 'Regex')
                                saveableObj.contentItem[prop] = validationObject.Value.value;
                            else if (typeof validationObject.Value.value !== 'string')
                                for (var p in validationObject.Value.value)
                                    saveableObj.contentItem[p] = validationObject.Value.value[p];
                            else if (prop === 'Regex')
                                saveableObj.contentItem['RegEx'] = decodeString(validationObject.Rule.regex);
                        }
                    }
                }
                var t = modifiedQuestions[index].Type;
                if (typeof modifiedQuestions[index].Control !== 'undefined' && t !== 'ShortText')
                    t = modifiedQuestions[index].Control;
                saveableObj.path = surveyPath + '/' + t + modifiedQuestions[index].Id;
                if (typeof saveableObj.contentItem.Name === 'undefined')
                    saveableObj.contentItem.Name = t + modifiedQuestions[index].Id;
                if (typeof saveableObj.contentItem.DisplayName === 'undefined')
                    saveableObj.contentItem.DisplayName = modifiedQuestions[index].Title;
                saveableObj.type = 'PUT';
                odata.editField(saveableObj);
            }
        }

        function getSaveableFields(type, control) {
            if (type === 'ShortText')
                type = 'ShortAnswer';
            else if (type === 'LongText')
                type = 'Paragraph';
            else if (type === 'Choice')
                type = control;
            else if (type === 'Number')
                if (typeof control !== 'undefined')
                    type = control;
            return SN.Fields[type].editor.schema.fields.SNFields;
        }

        function setBooleanValue(d, key, value, $input) {
            d[key] = value;
            $input.closest('.sn-survey-question').attr('data-edited', true);
            saveDataToTextBox();
        }

        function setStringValue(d, key, value, $input) {
            var sectionId = $input.closest('.sn-survey-section').attr('id');
            var section = getSectionById(sectionId);
            if (typeof section === 'undefined')
                section = d;
            section[key] = encodeString(value);
            $input.closest('.sn-survey-question').attr('data-edited', true);
            saveDataToTextBox(function () {
                refreshSectionTitlesAndJumpToSelects();
            });
        }

        function setTextareaValue($el, value, $input, key) {
            var sectionId = $input.closest('.sn-survey-section').attr('id');
            var section = getSectionById(sectionId);
            if (typeof section === 'undefined')
                section = d;
            section[key] = encodeString(value);
            $input.closest('.sn-survey-question').attr('data-edited', true);
            saveDataToTextBox(function () {
                refreshSectionTitlesAndJumpToSelects();
            });
        }

        function setReferenceValue(d, key, value, $input) {
            var sectionId = $input.closest('.sn-survey-section').attr('id');
            var section = getSectionById(sectionId);
            section[key] = value;
            $input.closest('.sn-survey-question').attr('data-edited', true);
            saveDataToTextBox(function () {
                refreshSectionTitlesAndJumpToSelects();
            });
        }

        function encodeString(string) {
            return encodeURIComponent(string).replace(/\-/g, "%2D").replace(/\_/g, "%5F").replace(/\./g, "%2E").replace(/\!/g, "%21").replace(/\~/g, "%7E").replace(/\*/g, "%2A").replace(/\'/g, "%27").replace(/\(/g, "%28").replace(/\)/g, "%29");
        }

        function decodeString(string) {
            if (typeof string === 'undefined')
                string = "";
            return decodeURIComponent(string.replace(/\%2D/g, "-").replace(/\%5F/g, "_").replace(/\%2E/g, ".").replace(/\%21/g, "!").replace(/\%7E/g, "~").replace(/\%2A/g, "*").replace(/\%27/g, "'").replace(/\%28/g, "(").replace(/\%29/g, ")"));
        }

        function saveDataToTextBox(callback) {
            setTimeout(function () {
                var json = removeTemplates(structureJSON);
                $structure.val(JSON.stringify(json));
                if (typeof callback !== 'undefined' && typeof callback === 'function')
                    callback();
            }, 500);

        }

        function getNewlyAddedQuestions() {
            var array = [];
            var count = $('.sn-survey-question[data-new="true"]').length;
            if (count > 0)
                for (var i = 0; i < count; i++)
                    array.push(survey.getQuestionByElement($($('.sn-survey-question[data-new="true"]')[i])));
            return array;
        }

        function removeTemplates(jsonData) {
            var json = $.extend(true, {
            }, jsonData);
            for (var i = 0; i < json.Sections.length; i++) {
                if (typeof json.Sections[i].questions !== 'undefined') {
                    for (var j = 0; j < json.Sections[i].questions.length; j++) {
                        if (typeof json.Sections[i].questions[j].Settings !== 'undefined') {
                            json.Sections[i].questions[j].Settings["template"] = '';
                            for (var prop in json.Sections[i].questions[j].Settings) {
                                if (typeof json.Sections[i].questions[j].Settings[prop] === 'object')
                                    json.Sections[i].questions[j].Settings[prop].template = "";
                            }
                        }
                    }
                }
            }
            return json;
        }

        function pushSectionToTheJson(section, index) {
            var newArray = [];

            for (var i = 0; i < index + 1; i++) {
                structureJSON.Sections[i].index = i;

                newArray.push(structureJSON.Sections[i]);
            }

            section.index = index;
            newArray.push(section);


            for (var j = index + 1; j < structureJSON.Sections.length; j++) {
                structureJSON.Sections[j].index = j;
                newArray.push(structureJSON.Sections[j]);
            }

            //newArray.push(structureJSON.Sections[structureJSON.Sections.length - 1]);

            structureJSON.Sections = newArray;

            return section;
        }

        function getFieldTypeByName(name) {
            var field;
            for (var fieldtype in SN.Fields) {
                if (SN.Fields[fieldtype].name === name) {
                    field = SN.Fields[fieldtype];
                }
            }
            return field;
        }

        function getFillTemplateByName(name) {
            var template;
            for (var fieldtype in SN.Fields) {
                if (SN.Fields[fieldtype].name === name || fieldtype === name)
                    template = SN.Fields[fieldtype].fill.template;
            }
            return template;
        }

        function loadJumpToSelect($el, id, next, index) {
            for (var i = 0; i < structureJSON.Sections.length; i++) {
                var $option;
                if (typeof structureJSON.Sections[i].title !== 'undefined' &&
                    structureJSON.Sections[i].title.length > 0 &&
                    structureJSON.Sections[i].id !== id &&
                    structureJSON.Sections[i].index >= index) {
                    $option = $('<option value="' + structureJSON.Sections[i].id + '">' + structureJSON.Sections[i].title + '</option>').appendTo($el);
                    if (typeof next !== 'undefined' && next === structureJSON.Sections[i].id)
                        $option.prop('selected', true);
                }
                if (!next)
                    $el.parent().remove();
            }
        }

        //section dragandrop related functions
        function sectionListReorderPlaceholder(element) {
            return element.clone().addClass("placeholder");
        }

        function sectionListReorderHint(element) {
            return element.clone().addClass("hint")
                        .height(element.height())
                        .width(element.width());
        }

        function saveSectionOrder(e) {
            var oldIndex = e.oldIndex + 1;
            var newIndex = e.newIndex;

            var section = getSectionByIndex(oldIndex);

            survey.deleteSection(section.id,
                function () {
                    survey.reAddSection(section, newIndex);
                }, true);

        }

        function questionListReorderPlaceholder(element) {
            return element.clone().addClass("placeholder");
        }

        function questionListReorderHint(element) {
            return element.clone().addClass("hint")
                        .height(element.height())
                        .width(element.width());
        }

        function saveQuestionOrder(e) {
            var $question = $(e.item);
            var questionId = $question.attr('id');
            var sectionId = $question.closest('.sn-survey-section').attr('id');
            var section = getSectionById(sectionId);
            var questionIndex = getQuestionIndexById(section, questionId);
            setTimeout(function () {
                reorderQuestions(section, e.oldIndex, e.newIndex, saveDataToTextBox);
            }, 500);
        }

        function reorderQuestions(section, oldindex, newindex, callback) {
            var newArray = [];

            $('#' + section.id).find('.sn-survey-questions').children('div:not(.placeholder)').each(function () {
                var id = $(this).attr('id');
                var question = getQuestionById(section, id);
                newArray.push(question);
            });

            section.questions = newArray;
            if (typeof callback !== 'undefined' && typeof callback === 'function')
                callback();
        }

        function createGuid() {
            function s4() {
                return Math.floor((1 + Math.random()) * 0x10000)
                  .toString(16)
                  .substring(1);
            }
            return s4() + s4();
        }

        function refreshSectionTitlesAndJumpToSelects() {
            $('.sn-survey-section').not('.placeholder, .sn-survey-settings').each(function () {
                var $this = $(this);
                var id = $this.attr('id');
                var section;
                if (typeof id !== 'undefined' && id !== 'intro' && id !== 'outro') {
                    section = getSectionById($this.attr('id'));
                    $this.attr('data-index', section.index);
                    var $title = $this.find('.sn-survey-section-title');
                    var titleArr = $title.text().split(' ');
                    var title = titleArr[0] + ' ' + section.index + '/' + (structureJSON.Sections.length - 2);
                    $title.text(title);
                }
            });
        }

        function getLastSection() {
            return structureJSON.Sections[structureJSON.Sections.length - 2];
        }

        function reindexJSONData(callback) {

            for (var i = 0; i < structureJSON.Sections.length; i++) {
                structureJSON.Sections[i].index = i;
            }
            callback();
        }

        function getSectionById(id) {
            var section;
            for (var i = 0; i < structureJSON.Sections.length; i++) {
                if (id === structureJSON.Sections[i].id)
                    section = structureJSON.Sections[i];
            }
            return section;
        }

        function getSectionByIndex(index) {
            var section;
            for (var i = 0; i < structureJSON.Sections.length; i++) {
                if (index === structureJSON.Sections[i].index)
                    section = structureJSON.Sections[i];
            }
            return section;
        }

        function getQuestionIndexById(section, id) {
            var questionIndex;
            for (var i = 0; i < section.questions.length; i++) {
                if (section.questions[i].Id === id)
                    questionIndex = i;
            }
            return questionIndex;
        }

        function getQuestionById(section, id) {
            var question;
            for (var i = 0; i < section.questions.length; i++)
                if (section.questions[i].Id === id)
                    question = section.questions[i];
            return question;
        }

        function createViewModel(data) {
            var question = {
            };
            for (var field in data.editor.schema.fields) {
                var defaultValue = data.editor.schema.fields[field].defaultValue;
                var type = data.editor.schema.fields[field].type;
                if (field === 'Validation') {
                    question[field] = data.editor.schema.fields[field];
                }
                else if (field === 'Id') {
                    question[field] = createGuid();
                }
                else {
                    if (typeof defaultValue !== 'undefined')
                        question[field] = data.editor.schema.fields[field].defaultValue;
                    else {
                        if (type === 'boolean')
                            question[field] = false;
                        else if (type === 'number')
                            question[field] = 0;
                        else
                            question[field] = '';
                    }
                }
            }

            return question;
        }

        function buildValidationRow($container, model, question, questionModel) {
            for (var field in model) {
                if (model[field].type === 'dropdown' && typeof model[field].cascadeFrom === 'undefined') {
                    createDropdown($container, model, field, question, questionModel);
                }
                else if (typeof model[field].cascadeFrom === 'undefined') {
                    if (model[field].type === 'string' || model[field].type === 'number')
                        createTextbox($container, model[field], field);
                }
            }
        }

        function createDropdown($container, model, field, question, questionModel) {
            var $select = $('<select class="validation-dropdown" id="' + field + '"></select>').appendTo($container);
            for (var property in question.editor.schema.validation.fields) {
                var prop = question.editor.schema.validation.fields[property];
                var placeHolder = '';
                var snFieldType = "ShortText";
                var $option;
                if (prop.length > 1) {
                    for (var i = 0; i < prop.length; i++) {
                        if (typeof prop[i].placeHolder !== 'undefined')
                            placeHolder = prop[i].placeHolder;
                        if (typeof prop[i].snFieldType !== 'undefined')
                            snFieldType = prop[i].snFieldType;
                        $option = $('<option value="' + prop[i].name + '" data-placeholder="' + placeHolder + '" data-snfield="' + snFieldType + '">' + prop[i].text + '</option>').appendTo($select);
                    }
                }
                else {
                    for (var j = 0; j < prop[0].rules.length; j++) {
                        if (typeof prop[0].rules[j].placeHolder !== 'undefined')
                            placeHolder = prop[0].rules[j].placeHolder;
                        if (typeof prop[0].rules[j].snFieldType !== 'undefined')
                            snFieldType = prop[0].rules[j].snFieldType;
                        $option = $('<option value="' + prop[0].rules[j].name + '"  data-type="' + prop[0].rules[j].type + '" data-placeholder="' + placeHolder + '" data-snfield="' + snFieldType + '">' + prop[0].rules[j].text + '</option>').appendTo($select);
                    }
                }
            }
            var cascadedField = getCascadedField(field, model);
            if (typeof cascadedField !== 'undefined' && cascadedField) {
                if (model[cascadedField].type === 'dropdown') {
                    var $cascadedSelect = $('<select class="cascaded-select" id="' + cascadedField + '"></select>').appendTo($container);
                    $('.validation-dropdown').on('change', function () {
                        var $this = $(this);
                        $cascadedSelect.html('');

                        var property = $this.attr('id');
                        var $selected = $this.find('option:selected');
                        var selectedValue = $selected.val();
                        var selectedType = $selected.attr('data-snfield');
                        var sectionId = $this.closest('.sn-survey-section').attr('id');
                        var section = getSectionById(sectionId);
                        var questionId = $this.closest('.sn-survey-question').attr('id');
                        var currentQuestion = getQuestionById(section, questionId);
                        currentQuestion.Type = selectedType;
                        var options = getOptionsToCascadedSelect(selectedValue, cascadedField, question.editor.schema.validation.fields[field]);
                        for (var j = 0; j < options.length; j++) {
                            var $op = $('<option value="' + options[j].name + '" data-type="' + options[j].type + '">' + options[j].text + '</option>').appendTo($cascadedSelect);
                        }

                        var saveableValidationField = property;
                        var saveableValue = selectedValue;
                        validationItem = getValidationItem(selectedValue, question.editor.schema.validation.fields[property]);
                        var snFieldType = validationItem.snFieldType;
                        if (typeof snFieldType !== 'undefined' && !$container.hasClass('hidden'))
                            currentQuestion.Validation.Type.value = snFieldType;
                        triggerCascadedTextbox($this.next('select'));
                        $cascadedSelect.next('input').attr('placeHolder', placeHolder).removeClass('hidden');


                    });
                }
            }
            else {
                $('.validation-dropdown').on('change', function () {
                    var $this = $(this);
                    var property = $this.attr('id');
                    var $selected = $this.find('option:selected');
                    var selectedValue = $selected.val();
                    var sectionId = $this.closest('.sn-survey-section').attr('id');
                    var section = getSectionById(sectionId);
                    var questionId = $this.closest('.sn-survey-question').attr('id');
                    var currentQuestion = getQuestionById(section, questionId);
                    validationItem = question.editor.schema.validation.fields['Type'][0];
                    var snFieldType = validationItem.snFieldType;
                    if (typeof snFieldType !== 'undefined' && !$container.hasClass('hidden')) {
                        currentQuestion.Validation.Type = {
                        };
                        currentQuestion.Validation.Type.value = snFieldType;
                    }
                    triggerCascadedTextbox($this);
                });
            }

            $('.cascaded-select').on('change', function () {
                triggerCascadedTextbox($(this));
            });

            $select.find('option:eq(0)').prop('selected', true);
        }

        function triggerCascadedTextbox($select) {
            var $that = $select;
            var sectionId = $that.closest('.sn-survey-section').attr('id');
            var section = getSectionById(sectionId);
            var questionId = $that.closest('.sn-survey-question').attr('id');
            var question = getQuestionById(section, questionId);
            var $question = $('#' + questionId);
            $question.find('span.error').addClass('hidden');
            var validationProperty = $that.attr('id');
            var selected = $that.find('option:selected').val();
            if (typeof selected === 'undefined')
                selected = $that.find('option').first().val();
            var selectedType = $that.find('option:selected').attr('data-type');
            var placeHolder = $that.find('option:selected').text();
            var validation;
            if (typeof question !== 'undefined') {
                validation = setSelectedValidationRule(validationProperty, selected, validationItem, question, $that, section);
                saveQuestionValidation(sectionId, questionId, validation);
            }

            var hasValue = optionsHasValue(validationItem['rules'], selected);
            if (typeof hasValue === 'undefined' || !hasValue)
                $that.next('input').addClass('hidden');
            else
                $that.next('input').removeClass('hidden');


            validation = getValidationByName(question.Type, selected);
            var width;
            if (typeof validation.snField !== 'undefined' && typeof validation.snField !== 'string') {
                if (validation.snField.length > 0) {
                    var $validationRow = $that.closest('.validation');
                    width = ($validationRow.width() - ($validationRow.find('#Type').width() || 0) - $validationRow.find('#Rule').width() - ($validationRow.find('#ErrorMessage').width() || 0)) / validation.snField.length - 30;

                    for (var i = 0; i < validation.snField.length; i++) {

                        if (i === 0) {
                            disposeAllDateWidgets(questionId);
                            $that.next('input').removeClass('hidden').attr({ 'class': 'additional-value', 'type': selectedType, 'placeHolder': SN.Resources.SurveyList[validation.snField[i]], 'id': validation.snField[i], 'style': 'width:' + width + 'px' });

                        }
                        if (i > 0) {
                            if (validation.type === 'date' || validation.type === 'time' || validation.type === 'dateandtime') {
                                $('<input class="additional-value" type="' + selectedType + '" id="' + validation.snField[i] + '" placeholder="' + SN.Resources.SurveyList[validation.snField[i]] + '" style="width:' + width + 'px" />').insertAfter($that.next('input'));
                            }
                            else {
                                if ($question.find('.additional-value').length > 1)
                                    $question.find('.additional-value').last().remove();
                                $('<input class="additional-value" type="' + selectedType + '" id="' + validation.snField[i] + '" placeholder="' + SN.Resources.SurveyList[validation.snField[i]] + '" style="width:' + width + 'px" />').insertAfter($that.next('input'));
                            }
                        }
                    }
                    if ((validation.name === 'between' || validation.name === 'betweenand') && validation.snField.length === 2) {
                        var timeoutId;
                        $question.find('.additional-value').on('input', function () {
                            clearTimeout(timeoutId);
                            timeoutId = setTimeout(function () {
                                validateBetweenValues($question.find('.additional-value'), validation.type);
                            }, 500);
                        });
                    }
                }
                $('.additional-value').on('input', function () {
                    changeTextBox($(this));
                });
            }
            else {
                disposeAllDateWidgets(questionId);
                $that.next('input').attr({
                    'type': selectedType,
                    'placeHolder': placeHolder,
                    'id': 'Value'
                }).css('width', '24%').removeClass('additional-value');
                $('#' + questionId).find('.additional-value').remove();
                if (question.Type !== 'datetime' && validation.name !== 'emailaddress' && validation.name !== 'urladdress')
                    $that.next('input').removeClass('hidden');
            }

            initDateTimeFields(selectedType, questionId, placeHolder, width, $('#' + questionId).find('.validation').find('.additional-value'));


        }

        function validateBetweenValues(inputs, type) {
            var $from = $(inputs[0]);
            var $till = $(inputs[1]);
            var from = $from.val();
            var till = $till.val();
            var $validationRow = $from.closest('.sn-survey-validationsettings-container');
            var $error;
            if ($validationRow.find('.error').length === 0) {
                $error = $('<span class="error"></span>').appendTo($validationRow);
                $error.addClass('hidden').text(SN.Resources.SurveyList["MinIsGreaterThanMaxErrorMessage"]);
            }
            else
                $error = $validationRow.find('.error');

            switch (type) {
                case 'number':
                    if (from !== '' && till !== '' && Number(from) >= Number(till))
                        $error.removeClass('hidden');
                    else
                        $error.addClass('hidden');
                    break;
                case 'date':
                    var fromDate, tillDate;
                    if (from.indexOf('/') === -1) {
                        fromDate = from.replace(':', '');
                        tillDate = till.replace(':', '');
                    }
                    else {
                        fromDate = new Date(from);
                        tillDate = new Date(till);
                    }
                    if (from !== '' && till !== '' && fromDate >= tillDate)
                        $error.removeClass('hidden');
                    else
                        $error.addClass('hidden');
                default:
                    break;
            }

        }

        function initDateTimeFields(selectedType, id, placeHolder, width, additional) {
            var $input = $('#' + id).find('#Value');
            var timePicker = $input.data("kendoTimePicker");
            var datetimePicker = $input.data("kendoDateTimePicker");
            var datePicker = $input.data("kendoDatePicker");
            if (timePicker)
                disposeTimePicker(timePicker);
            if (datePicker)
                disposeDatePicker(datePicker);
            if (datetimePicker)
                disposeDateTimePicker(datetimePicker);

            if (selectedType === 'date') {
                $input.kendoDatePicker({
                    change: changeTextBox
                });
                $input.closest(".k-widget").width(width);
            }
            else if (selectedType === 'dateandtime') {
                $input.kendoDateTimePicker({
                    timeFormat: "HH:mm",
                    format: "yyyy-MM-dd HH:mm",
                    parseFormats: ["yyyy-MM-dd HH:mm", "HH:mm"],
                    change: changeTextBox
                });
                $input.closest(".k-widget").width(width);
            }
            else if (selectedType === 'time') {
                $input.kendoTimePicker({
                    format: "HH:mm",
                    change: changeTextBox
                });
                $input.closest(".k-widget").width(width);
            }

            if (additional.length > 0) {
                additional.each(function () {
                    var $this = $(this);

                    if (selectedType === 'date') {
                        $this.kendoDatePicker({
                            change: changeTextBox
                        });
                        $this.closest(".k-widget").width(width);
                    }
                    else if (selectedType === 'dateandtime') {
                        $this.kendoDateTimePicker({
                            timeFormat: "HH:mm",
                            format: "yyyy-MM-dd HH:mm",
                            parseFormats: ["yyyy-MM-dd HH:mm", "HH:mm"],
                            change: changeTextBox
                        });
                        $this.closest(".k-widget").width(width);
                    }
                    else if (selectedType === 'time') {
                        $this.kendoTimePicker({
                            format: "HH:mm",
                            change: changeTextBox
                        });
                        $this.closest(".k-widget").width(width);
                    }
                });
            }
            else
                $input.attr('placeholder', placeHolder);
        }

        function disposeAllDateWidgets(id) {
            $('#' + id).find('.validation').find('input').each(function () {
                var $input = $(this);
                var timePicker = $input.data("kendoTimePicker");
                var datetimePicker = $input.data("kendoDateTimePicker");
                var datePicker = $input.data("kendoDatePicker");
                if (timePicker)
                    disposeTimePicker(timePicker);
                if (datePicker)
                    disposeDatePicker(datePicker);
                if (datetimePicker)
                    disposeDateTimePicker(datetimePicker);
            });
        }

        function disposeDatePicker(datepicker) {
            var popup = datepicker.dateView.popup,
            element = popup.wrapper[0] ? popup.wrapper : popup.element;

            //remove popup element;
            element.remove();
            //unwrap element
            var input = datepicker.element.show();

            input.removeClass("k-input").css("width", "auto");
            input.insertBefore(datepicker.wrapper);

            datepicker.wrapper.remove();

            //remove DatePicker object
            input.removeData("kendoDatePicker");
            input.val('');
        }

        function disposeDateTimePicker(datepicker) {
            var popup = datepicker.dateView.popup,
            element = popup.wrapper[0] ? popup.wrapper : popup.element;

            //remove popup element;
            element.remove();
            //unwrap element
            var input = datepicker.element.show();

            input.removeClass("k-input").css("width", "auto");
            input.insertBefore(datepicker.wrapper);

            datepicker.wrapper.remove();

            //remove DatePicker object
            input.removeData("kendoDateTimePicker");
            input.val('');
        }

        function disposeTimePicker(datepicker) {

            //unwrap element
            var input = datepicker.element.show();

            input.removeClass("k-input").css("width", "auto");
            input.insertBefore(datepicker.wrapper);

            datepicker.wrapper.remove();

            //remove DatePicker object
            input.removeData("kendoTimePicker");
            input.val('');
        }

        function setSelectedValidationRule(property, selected, validationSchema, question, $element, section) {

            var validations = $.extend(true, {
            }, question.Validation);
            var saveableValidationField = property;
            var saveableValue = selected;
            var validItem = getValidationItem(selected, validationSchema["rules"]);
            var snField = validItem.snField;
            var snFieldType = validItem.snFieldType;
            var regex = validItem.pattern;
            var method = validItem.method;

            if (typeof regex !== 'undefined') {
                if (!$element.closest('.validation').hasClass('hidden')) {
                    validations.Rule.value = validItem.name;
                    validations.Rule.regex = encodeString(regex);
                }
                $element.next('input').addClass('hidden');

            }
            else if (typeof snFieldType !== 'undefined') {
                if (!$element.closest('.validation').hasClass('hidden')) {
                    if (snFieldType === 'WholeNumber')
                        validations.Rule.value = 'WholeNumber';
                    else
                        validations.Rule.value = '';
                    question.Type = snFieldType;
                }
                $element.next('input').addClass('hidden');
            }
            else if (typeof snField !== 'undefined' && typeof snField === 'string') {
                if (!$element.closest('.validation').hasClass('hidden')) {
                    validations.Rule.value = snField;
                    if (snField === 'Regex')
                        validations.Rule.regexRule = validItem.name;
                }
                $element.next('input').removeClass('hidden').attr('placeHolder', validItem.text);
            }
            else if (typeof snField !== 'undefined' && typeof snField !== 'string') {
                if (!$element.closest('.validation').hasClass('hidden')) {
                    validations.Rule.value = validItem.name;
                }
                $element.next('input').removeClass('hidden').attr('placeHolder', validItem.text);
            }
            else {
                if (!$element.closest('.validation').hasClass('hidden')) {
                    validations.Rule.value = validItem.name;
                    validations.Rule.valueType = validItem.type;
                }
            }
            if (!$element.closest('.validation').hasClass('hidden')
                && typeof question.Validation.Rule.regex === 'undefined') {
                $element.closest('.sn-survey-question').attr('data-edited', true);
                saveDataToTextBox();
            }
            return validations;
        }

        function saveQuestionValidation(sectionid, questionId, question) {
            for (var i = 0; i < structureJSON.Sections.length; i++) {
                if (structureJSON.Sections[i].id === sectionid) {
                    for (var j = 0; j < structureJSON.Sections[i].questions.length; j++) {
                        if (structureJSON.Sections[i].questions[j].Id === questionId)
                            structureJSON.Sections[i].questions[j].Validation = question;
                    }
                }
            }
            saveDataToTextBox();
        }

        function createTextbox($container, field, name) {
            var type = 'text';
            if (field.type === 'number')
                type = field.type;

            var placeHolder = '';
            if (typeof field.placeHolder !== 'undefined')
                placeHolder = field.placeHolder;

            if (!field.hidden)
                var $input = $('<input placeHolder="' + placeHolder + '" type="' + type + '" id="' + name + '" />').appendTo($container);

            $container.find('input[type=text]').on('input', function () {
                changeTextBox($(this));
            });
        }

        function changeTextBox($this) {
            if (typeof $this.attr !== 'function')
                $this = $($this.sender.element);
            var property = $this.attr('id');
            var sectionId;
            if (typeof propery === 'undefined')
                sectionId = $this.closest('.sn-survey-section').attr('id');
            var section = getSectionById(sectionId);
            var questionId = $this.closest('.sn-survey-question').attr('id');
            var question = getQuestionById(section, questionId);
            var validation = question.Validation;
            if (property === 'Value' || property === 'ErrorMessage') {
                validation[property].value = encodeString($this.val());
                if (validation.Rule.value === 'Regex' && property === 'Value')
                    validation.Rule.regex = encodeString($this.val());
            }
            else {
                var propertyArray = validation['Value'].value;
                if (typeof propertyArray === 'undefined' || typeof propertyArray !== 'object')
                    propertyArray = {
                    };
                propertyArray[property] = encodeString($this.val());
                validation['Value'].value = propertyArray;
            }
            $this.closest('.sn-survey-question').attr('data-edited', true);
            var inputs = $this.closest('.sn-survey-validationsettings-container').find('input.additional-value');
            if (inputs.length > 1)
                validateBetweenValues(inputs, 'date');
            saveDataToTextBox();
        }

        function getCascadedField(name, model) {
            var field;
            for (var obj in model)
                if (model[obj].cascadeFrom === name)
                    field = obj;
            return field;
        }

        function getOptionsToCascadedSelect(name, field, question) {
            var options;
            for (var i = 0; i < question.length; i++) {
                if (question[i].name === name)
                    options = question[i].rules;
            }
            return options;
        }

        function getValidationValueInput(sel, validationJson) {
            var novalue = true;
            for (var i = 0; i < validationJson.length; i++) {
                if (validationJson[i].name === sel && typeof validationJson[i].value !== 'undefined')
                    novalue = validationJson[i].value;
            }
            return novalue;
        }

        function getValidationItem(name, array) {
            var item;
            for (var i = 0; i < array.length; i++) {
                if (array[i].name === name)
                    item = array[i];
            }
            return item;
        }

        function saveDefaultFields(callback) {
            var title = $surveyTitle.val();
            var description = $surveyDescription.val();
            var intro = $intro.val();
            var outro = $outro.val();
            var json = $structure.val();
            var landingPagePath, landingPageArray = [];
            if (SN.Util.isNotUndefined($('[name="landingPage"]')))
                if (typeof $('[name="landingPage"]').attr('title') !== 'undefined')
                    if ($('[name="landingPage"]').attr('title').length > 0)
                        landingPageArray.push($('[name="landingPage"]').attr('title'));

            if (structureJSON.Sections.length > 2) {
                kendo.ui.progress($form, true);
                var content = {
                    path: surveyPath,
                    contentItem: {
                        __ContentType: 'SurveyList',
                        DisplayName: title,
                        Description: description,
                        IntroText: intro,
                        OutroText: outro,
                        RawJson: json,
                        OnlySingleResponse: structureJSON.OnlySingleResponse,
                        LandingPage: landingPageArray
                    },
                    success: function (data) {
                        if (structureJSON.Sections.length > 2) {
                            if (typeof callback === 'function')
                                callback(data.d.Name, function () {
                                    saveNewFields(data.d.Name);
                                    savedFieldsNumber = 0;
                                });
                            else {
                                saveNewFields(data.d.Name);
                                savedFieldsNumber = 0;
                            }
                        }
                        else {
                            if (typeof callback === 'function')
                                callback(data.d.Name, function () {
                                    window.location.href = surveyPath;
                                });
                            else
                                window.location.href = surveyPath;
                        }
                    },
                    error: function (xhr, status, text) {
                        var response = $.parseJSON(xhr.responseText);
                        var $overlay = overlayManager.showMessage({
                            type: "error",
                            title: 'Error',
                            text: response
                        });
                    }
                };
                var hasQuestions = surveyHasQuestions();
                if (hasQuestions)
                    odata.createContent(content);
                else {
                    var $overlay1 = overlayManager.showMessage({
                        type: "error",
                        title: 'Error',
                        text: SN.Resources.SurveyList["errorMessageNoQuestion"]
                    });
                    setTimeout(function () {

                        kendo.ui.progress($form, false);
                        overlayManager.hideMessage();
                        $('.sn-submit').show();
                        $('.sn-submit-disabled').hide();
                    }, 2000);
                }

            }
            else {
                var $overlay2 = overlayManager.showMessage({
                    type: "error",
                    title: 'Error',
                    text: SN.Resources.SurveyList["errorMessageNoSection"]
                });
                setTimeout(function () {
                    kendo.ui.progress($form, false);
                    overlayManager.hideMessage();
                    $('.sn-submit').show();
                    $('.sn-submit-disabled').hide();
                }, 2000);
            }
        }

        function saveNewFields(name, newFields) {
            var saveAbleQuestions = [];
            var array = [], count, index = 1;
            if (typeof newFields === 'undefined') {
                array = structureJSON.Sections;
                count = array.length - 1;
            }
            else {
                index = 0;
                array = newFields;
                count = array.length;
            }


            if (typeof newFields !== 'undefined') {
                index = 0;
                array = newFields;
            }
            var a2, path, question, saveableQuestion;
            if (typeof newFields === 'undefined') {
                for (var i = index; i < count; i++) {
                    var section = array[i];
                    a2 = section.questions;
                    if (typeof newFields !== 'undefined') {
                        a2 = newFields;
                    }
                    path = surveyPath + '/' + name;
                    if (view === 'edit')
                        path = surveyPath;
                    if (array.length > 0) {
                        for (var j = 0; j < a2.length; j++) {
                            question = a2[j];
                            if (question.Type === 'ShortText') {
                                saveableQuestion = createShortField(path, question);
                            }
                            else if (question.Type === 'Number') {
                                saveableQuestion = createShortField(path, question);
                            }
                            else if (question.Type === 'Range') {
                                saveableQuestion = createShortField(path, question);
                            }
                            else if (question.Type === 'WholeNumber') {
                                saveableQuestion = createShortField(path, question);
                            }
                            else if (question.Type === 'LongText') {
                                saveableQuestion = createLongField(path, question);
                            }
                            else if (question.Type === 'Boolean') {
                                saveableQuestion = createBooleanField(path, question);
                            }
                            else if (question.Type === 'DateTime') {
                                saveableQuestion = createDateTimeField(path, question);
                            }
                            else if (question.Type === 'Choice') {
                                saveableQuestion = createChoiceField(path, question);
                            }
                            else if (question.Type === 'Reference') {
                                saveableQuestion = createUploadField(path, question);
                            }
                            else {
                                saveableQuestion = createLongField(path, question);
                            }
                            if (question.Type === 'Reference') {
                                odata.createContent({
                                    path: path,
                                    contentItem: { __ContentType: 'Folder', Name: 'Files-' + question.Id, DisplayName: 'Files-' + question.Title }
                                });
                            }
                            saveAbleQuestions.push(saveableQuestion);
                        }
                    }
                }
            }
            else {
                a2 = newFields;
                path = surveyPath + '/' + name;
                if (view === 'edit')
                    path = surveyPath;
                if (array.length > 0) {
                    for (var x = 0; x < a2.length; x++) {
                        question = a2[x];
                        if (question.Type === 'ShortText') {
                            saveableQuestion = createShortField(path, question);
                        }
                        else if (question.Type === 'Number') {
                            saveableQuestion = createShortField(path, question);
                        }
                        else if (question.Type === 'Range') {
                            saveableQuestion = createShortField(path, question);
                        }
                        else if (question.Type === 'WholeNumber') {
                            saveableQuestion = createShortField(path, question);
                        }
                        else if (question.Type === 'LongText') {
                            saveableQuestion = createLongField(path, question);
                        }
                        else if (question.Type === 'Boolean') {
                            saveableQuestion = createBooleanField(path, question);
                        }
                        else if (question.Type === 'DateTime') {
                            saveableQuestion = createDateTimeField(path, question);
                        }
                        else if (question.Type === 'Choice') {
                            saveableQuestion = createChoiceField(path, question);
                        }
                        else if (question.Type === 'Reference') {
                            saveableQuestion = createUploadField(path, question);
                        }
                        else {
                            saveableQuestion = createLongField(path, question);
                        }
                        if (question.Type === 'Reference') {
                            odata.createContent({
                                path: path,
                                contentItem: { __ContentType: 'Folder', Name: 'Files-' + question.Id, DisplayName: 'Files-' + question.Title }
                            });
                        }
                        saveAbleQuestions.push(saveableQuestion);
                    }
                }
            }


            if (saveAbleQuestions.length > 0)
                recursiveSave(saveAbleQuestions, 0);
            else {
                var $overlay = overlayManager.showMessage({
                    type: "error",
                    title: 'Error',
                    text: SN.Resources.SurveyList["errorMessageNoQuestion"]
                });
                setTimeout(function () {

                    kendo.ui.progress($form, false);
                    overlayManager.hideMessage();
                    $('.sn-submit').show();
                    $('.sn-submit-disabled').hide();
                }, 2000);
            }
        }

        function saveSettings(name, callback) {
            var contentItem = {};
            for (var i = 0; i < $('#settingsWindow').find('.sn-formrow').length; i++) {
                var $this = $($('#settingsWindow').find('.sn-formrow')[i]);
                var fieldName, fieldValue;
                if ($this.find('textarea').length > 0) {
                    fieldName = $this.find('textarea').attr('name');
                    fieldValue = $this.find('textarea').val();
                    if (typeof fieldName !== 'undefined')
                        contentItem[fieldName] = fieldValue;
                }
                else if ($this.find('input').length > 0) {
                    fieldName = $this.find('input').attr('name');
                    fieldValue = $this.find('input').val();
                    if ($this.find('input').is(':checkbox'))
                        fieldValue = $this.find('input').is(':checked');
                    if (fieldName === 'ValidFrom' || fieldName === 'ValidTill') {
                        if (fieldValue === "")
                            fieldValue = null;
                        else
                            fieldValue = moment(fieldValue).format();
                    }
                    if (fieldName === 'EmailField')
                        fieldValue = '#' + $this.find('input').val();
                    if (typeof fieldName !== 'undefined')
                        contentItem[fieldName] = fieldValue;
                }
            }

            var s = {};
            s['path'] = surveyPath + '/' + name;
            s['contentItem'] = contentItem;
            s['success'] = callback;
            odata.saveContent(s);
        }

        function recursiveSave(array, num) {
            if (num < array.length) {
                if (num === array.length - 1)
                    array[num].success = function () {
                        if (!notValid)
                            window.location.href = surveyPath;
                        else {
                            kendo.ui.progress($form, false);
                            saveDataToTextBox(function () {
                                var s = {};
                                s['path'] = array[num].path;
                                s['contentItem'] = { 'RawJson': $structure.val() };
                                odata.saveContent(s);
                            });
                        }
                    };
                else
                    array[num].success = function () {
                        num += 1;
                        recursiveSave(array, num);
                    };
                array[num].error = function (xhr, status, text) {
                    var response = $.parseJSON(xhr.responseText);
                    overlayManager.hideOverlay();
                    var $overlay = overlayManager.showOverlay({
                        text: '<span class="fa fa-warning"></span>' + SN.Resources.SurveyList["QuestionIsNotValid"] + '</br><strong>' + array[num].contentItem.DisplayName + '</strong>' + '</br>' + SN.Resources.SurveyList["error"] + response.error.message.value,
                        cssClass: "popup-error",
                        appendCloseButton: true,
                        onclose: function () {
                            window.location.href = surveyPath;
                        }
                    });
                    notValid = true;
                    removeQuestionFromJson(array[num]);
                    if (num !== array.length - 1) {
                        num += 1;
                        recursiveSave(array, num);
                    }
                };
                odata.createContent(array[num]);
            }
        }

        function removeQuestionFromJson(question) {
            for (var i = 1; i < structureJSON.Sections.length - 1; i++) {
                for (var j = 0; j < structureJSON.Sections[i].questions.length; j++) {
                    if (question.contentItem.Name.indexOf(structureJSON.Sections[i].questions[j].Id) > -1)
                        structureJSON.Sections[i].questions.splice(j, 1);
                }
            }

        }

        function createShortField(path, question) {
            var type = question.Type, field;
            var name = type + question.Id;
            var content;
            if (type === 'ShortText') {
                content = {
                    path: path,
                    contentItem: {
                        __ContentType: 'ShortTextFieldSetting',
                        Name: question.Type + question.Id,
                        DisplayName: question.Title,
                        Description: question.Hint,
                        Compulsory: question.Required
                    }
                };
            }
            else if (type === 'Number') {
                content = {
                    path: path,
                    contentItem: {
                        __ContentType: 'NumberFieldSetting',
                        Name: question.Type + question.Id,
                        DisplayName: question.Title,
                        Description: question.Hint,
                        Compulsory: question.Required
                    }
                };
            }
            else if (type === 'WholeNumber') {
                content = {
                    path: path,
                    contentItem: {
                        __ContentType: 'IntegerFieldSetting',
                        Name: question.Type + question.Id,
                        DisplayName: question.Title,
                        Description: question.Hint,
                        Compulsory: question.Required
                    }
                };
            }
            else if (type === 'Range') {
                content = {
                    path: path,
                    contentItem: {
                        __ContentType: 'NumberFieldSetting',
                        Name: question.Type + question.Id,
                        DisplayName: question.Title,
                        Description: question.Hint,
                        Compulsory: question.Required
                    }
                };
            }

            if (typeof question.Validation !== 'undefined') {
                var validation = getValidationRule(question.Validation);
                if (typeof validation.value !== 'object')
                    content.contentItem[validation.field] = decodeString(validation.value);
                else {
                    for (var prop in validation.value) {
                        content.contentItem[prop] = decodeString(validation.value[prop]);
                    }
                }
            }
            return content;
        }

        function createLongField(path, question) {
            var type = question.Type, field;
            var title = question.title;
            if (typeof title === 'undefined' || title === '')
                title = 'Untitled question';
            var content = {
                path: path,
                contentItem: {
                    __ContentType: 'LongTextFieldSetting',
                    Name: question.Type + question.Id,
                    DisplayName: question.Title,
                    Description: question.Hint,
                    Compulsory: question.Required
                }
            };
            if (typeof question.Validation !== 'undefined') {
                var validation = getValidationRule(question.Validation);
                content.contentItem[validation.field] = validation.value;
            }
            return content;
        }

        function createBooleanField(path, question) {
            var type = question.Type, field;
            var content = {
                path: path,
                contentItem: {
                    __ContentType: 'YesNoFieldSetting',
                    Name: question.Type + question.Id,
                    DisplayName: question.Title,
                    Description: question.Hint,
                    Compulsory: question.Required
                }
            };
            return content;
        }

        function createDateTimeField(path, question) {
            var type = question.Type, field;
            var content = {
                path: path,
                contentItem: {
                    __ContentType: 'DateTimeFieldSetting',
                    Name: question.Type + question.Id,
                    DisplayName: question.Title,
                    Description: question.Hint,
                    Compulsory: question.Required
                }
            };
            return content;
        }

        function createChoiceField(path, question) {
            var type = question.Type, field;
            if (typeof question.Control !== 'undefined')
                type = question.Control;
            var options = '<Options>';
            var option;

            if (!question.Other) {
                for (var i = 0; i < question.Options.length; i++) {
                    option = '<Option value=\"' + encodeString(question.Options[i].title) + '\">' + question.Options[i].title + '</Option>';
                    options += option;
                }
            }
            else
                for (var j = 0; j < question.Options.length - 1; j++) {
                    option = '<Option value=\"' + encodeString(question.Options[j].title) + '\">' + question.Options[j].title + '</Option>';
                    options += option;
                }
            options += '</Options>';
            var content = {
                path: path,
                contentItem: {
                    __ContentType: 'ChoiceFieldSetting',
                    Name: type + question.Id,
                    DisplayName: question.Title,
                    Description: question.Hint,
                    Options: options,
                    AllowExtraValue: question.Other,
                    AllowMultiple: question.Multiple
                }
            };
            return content;
        }

        function createUploadField(path, question) {
            var type = question.Type, field;
            var name = type + question.Id;

            var content = {
                path: path,
                contentItem: {
                    __ContentType: 'ReferenceFieldSetting',
                    Name: question.Type + question.Id,
                    DisplayName: question.Title,
                    Description: question.Hint,
                    Compulsory: question.Required,
                    AllowMultiple: question.AllowMultiple
                }
            };
            return content;

        }

        function getValidationRule(validationObj) {
            var validation = {
                field: '',
                value: ''
            };
            if (typeof validationObj.Value.value !== 'undefined') {
                validation.field = validationObj.Rule.value;
                validation.value = validationObj.Value.value;
            }
            else {
                validation.field = validationObj.Rule.value;
                validation.value = validationObj.Rule.regex;
            }

            return validation;
        }

        function getValidationRuleByName(name, type) {
            var value;
            for (var i = 0; i < SN.Fields[type].editor.schema.validation.fields.Type.length; i++)
                for (var j = 0; j < SN.Fields[type].editor.schema.validation.fields.Type[i].rules.length; j++)
                    if (SN.Fields[type].editor.schema.validation.fields.Type[i].rules[j].snField === name)
                        value = SN.Fields[type].editor.schema.validation.fields.Type[i].rules[j].name;
            return value;
        }

        function bindValidation($input, question, type) {
            var validation = question.Validation;
            var ruleName = decodeString(validation.Rule.value);

            if (ruleName === '' && type !== 'undefined' && type !== 'datetime') {
                if (typeof question.Control !== 'undefined')
                    type = question.Control;
                else
                    type = question.Type;
                ruleName = SN.Fields[type].editor.schema.validation.fields.Type[0].rules[0].name;
            }

            var ruleValue;
            if (typeof validation.Value.value === 'string')
                ruleValue = decodeString(validation.Value.value);
            else
                ruleValue = createValidationStringFromObject(validation.Value.value);

            var errorMessage;
            if (type === "choice" && question.Required) {
                ruleName = 'option-required';
                ruleValue = true;
                errorMessage = SN.Resources.SurveyList["Required"];
            }
            else if (type === "grid" && question.Required) {
                ruleName = 'grid-required';
                ruleValue = true;
                errorMessage = SN.Resources.SurveyList["Required"];
            }

            if (typeof ruleValue === 'undefined')
                ruleValue = '';
            if (typeof validation.ErrorMessage !== 'undefined')
                errorMessage = decodeString(validation.ErrorMessage.value);
            var attributeName = 'data-' + ruleName;
            var valueName = attributeName + '-value';
            var regex = decodeString(validation.Rule.regex);
            $input.attr('data-validate', '');
            if (ruleName === 'Regex') {
                attributeName = 'data-' + validation.Rule.regexRule;
                valueName = attributeName + '-value';
                $input.attr(attributeName, '').attr(valueName, regex).attr('sn-pattern', regex).attr(attributeName + '-msg', errorMessage);
            }
            else if (typeof regex !== 'undefined' && regex.length > 0)
                $input.attr(attributeName, '').attr(valueName, ruleValue).attr('sn-pattern', regex).attr(attributeName + '-msg', errorMessage);
            else {
                if ((typeof question.CustomRequired !== 'undefined' && question.Required) || typeof question.CustomRequired === 'undefined')
                    $input.attr(attributeName, '').attr(valueName, ruleValue).attr(attributeName + '-msg', errorMessage);
            }
        }

        function createValidationObj() {
            for (var i = 0; i < structureJSON.Sections.length; i++) {
                var section = structureJSON.Sections[i];
                if (typeof section.questions !== 'undefined' && section.questions.length > 0)
                    for (var j = 0; j < section.questions.length; j++) {
                        var question = section.questions[j];
                        var type = question.Type;
                        if (typeof question.Control !== 'undefined')
                            type = question.Control;
                        var validation = question.Validation;
                        if (typeof validation !== 'undefined') {
                            var ruleName = validation.Rule.value;
                            if (typeof ruleName !== 'undefined')
                                ruleName = ruleName.toLowerCase();
                            else {
                                ruleName = SN.Fields[type].editor.schema.validation.fields.Type[0].rules[0].name;
                            }

                            if (ruleName === 'regex' && typeof validation.Rule.regexRule !== 'undefined' && validation.Rule.regexRule !== '')
                                ruleName = validation.Rule.regexRule;

                            var ruleValue = validation.Value.value;
                            var value = validation.Rule.value;
                            if (typeof value === 'undefined')
                                value = ruleName;

                            if (typeof section.questions[j].CustomRequired !== 'undefined' && section.questions[j].Required) {
                                ruleName = section.questions[j].CustomRequired;
                                value = section.questions[j].CustomRequired;
                            }
                            if (typeof value !== 'undefined') {
                                if (value === 'Regex')
                                    value = validation.Rule.regexRule;
                                var validationSchema = getValidationByName(type, value, section.questions[j]);
                                if (typeof validationSchema !== 'undefined' && typeof validationSchema.method !== 'undefined' && typeof validator.options.rules[ruleName] === 'undefined') {
                                    validator.options.rules[ruleName] = validationSchema.method;
                                    if (typeof validation.ErrorMessage !== 'undefined' && typeof validation.ErrorMessage.value !== 'undefined' && validation.ErrorMessage.value.length > 0)
                                        validator.options.messages[ruleName] = validation.ErrorMessage.value;
                                    else if (typeof validationSchema.errorMessage !== 'undefined' && validationSchema.errorMessage.length > 0)
                                        validator.options.messages[ruleName] = validationSchema.errorMessage;
                                }
                            }
                        }
                    }
            }
            return validator;
        }

        function optionsHasValue(validationRules, name) {
            var hasValue = true;
            for (var i = 0; i < validationRules.length; i++) {
                if (validationRules[i].name === name)
                    hasValue = validationRules[i].value;
            }
            return hasValue;
        }

        function getValidationByName(type, name, question) {
            var schema;
            if (type === 'WholeNumber')
                type = 'Number';
            else if (type === 'ShortText')
                type = 'ShortAnswer';
            else if (type === 'LongText')
                type = 'Paragraph';
            if (typeof question !== 'undefined' && typeof question.Control !== 'undefined')
                type = question.Control;
            if (typeof SN.Fields[type].editor.schema.validation !== 'undefined') {
                for (var i = 0; i < SN.Fields[type].editor.schema.validation.fields.Type.length; i++) {
                    var vType = SN.Fields[type].editor.schema.validation.fields.Type[i];
                    for (var j = 0; j < vType.rules.length; j++) {
                        if (vType.rules[j].name === name || vType.rules[j].name === name.toLowerCase() || (vType.rules[j].snField !== 'RegEx' && vType.rules[j].snField === name))
                            schema = vType.rules[j];
                    }
                }
            }
            return schema;
        }

        function getSaveableAnswers() {
            var content = {
                __ContentType: 'SurveyListItem'
            };
            survey.$el.find('.sn-question').each(function () {
                var $this = $(this);
                var type = $this.attr('data-fieldtype');
                var id = $this.attr('data-qid');
                var fieldName = '#' + type + id;
                var value;
                switch (type) {
                    case 'ShortText':
                        value = $this.find('input[type="text"]').val();
                        break;
                    case 'ShortAnswer':
                        value = $this.find('input[type="text"]').val();
                        fieldName = '#ShortText' + id;
                        break;
                    case 'Number':
                        value = $this.find('input[type="number"]').val();
                        break;
                    case 'WholeNumber':
                        value = $this.find('input[type="number"]').val();
                        break;
                    case 'Boolean':
                        if ($this.find('input[type="checkbox"]').is(':checked'))
                            value = 'yes';
                        else
                            value = 'no';
                        break;
                    case 'LongText':
                        value = $this.find('textarea.sn-answer').val();
                        break;
                    case 'Paragraph':
                        value = $this.find('textarea.sn-answer').val();
                        fieldName = '#LongText' + id;
                        break;
                    case 'Range':
                        value = $this.find('input[type="text"]').val();
                        break;
                    case 'Radio':
                        if ($this.find('input[type="radio"]:checked').parent().hasClass('other'))
                            value = '~other.' + $this.find('input[type="radio"]:checked').siblings('input[name="otherValue"]').val();
                        else
                            value = $this.find('input[type="radio"]:checked').val();
                        break;
                    case 'DropDown':
                        if ($this.find('option:selected').hasClass('other'))
                            value = '~other.' + $this.find('option:selected').parent('select').siblings('input[name="other"]').val();
                        else
                            value = $this.find('option:selected').val();
                        break;
                    case 'Checkbox':
                        var options = [];
                        for (var i = 0; i < $this.find('input[type="checkbox"]:checked').length; i++) {
                            if ($($this.find('input[type="checkbox"]:checked')[i]).parent().hasClass('other'))
                                value = '~other.' + $($this.find('input[type="checkbox"]:checked')[i]).siblings('input[name="otherValue"]').val();
                            else
                                value = $($this.find('input[type="checkbox"]:checked')[i]).val();
                            options.push(value);
                        }
                        value = options;
                        break;
                    case 'Upload':
                        fieldName = '#Reference' + id;
                        if (typeof SN.Fields[type].fill.value === 'function')
                            value = SN.Fields[type].fill.value($this, id);
                        break;
                    default:
                        if (typeof SN.Fields[type].fill.value === 'function')
                            value = SN.Fields[type].fill.value($this, id);
                        break;
                }
                if (value !== '')
                    content[fieldName] = value;
            });
            return content;
        }
        function surveyHasQuestions() {
            var hasQuestion = false;
            for (var i = 0; i < structureJSON.Sections.length; i++) {
                if (typeof structureJSON.Sections[i].questions !== 'undefined' && structureJSON.Sections[i].questions.length > 0) {
                    hasQuestion = true;
                    break;
                }
            }
            return hasQuestion;
        }

        // change progressbar color by progress

        function onProgressChange(e) {
            var progress = e.value;
            var max = structureJSON.Sections.length - 1;
            if (typeof intro === "undefined" || intro.length === 0)
                max = structureJSON.Sections.length - 2;
            var rate = e.value / max;
            var selected = e.sender.wrapper.find(".k-state-selected");

            switch (true) {
                case (rate <= 0.33):
                    $(selected).addClass('lowFill').removeClass('middleFill highFill readyFill');
                    break;
                case (rate <= 0.66):
                    $(selected).addClass('middleFill').removeClass('lowFill highFill readyFill');
                    break;
                case (rate < 0.99):
                    $(selected).addClass('highFill').removeClass('middleFill lowFill readyFill');
                    break;
                default:
                    $(selected).addClass('readyFill').removeClass('middleFill highFill lowFill');
            }
        }

        function createValidationStringFromObject(value) {
            var string = '';
            for (var prop in value) {
                if (string === '')
                    string += value[prop]
                else
                    string += ',' + value[prop];
            }
            return string;
        }

        function validateFieldsOneByOne() {
            var valid = false;
            var notValid = 0;
            for (var i = 0; i < survey.$el.find('[data-validate]').length; i++) {
                var $obj = survey.$el.find('[data-validate]').eq(i);
                if (!validator.validateInput($obj))
                    notValid += 1;
            }
            if (notValid === 0)
                valid = true;

            return valid;
        }

        function isShortText($element) {
            return $element.attr('data-fieldtype') === 'ShortText';
        }

        function deleteQuestionConfirmation(title, sid, qid, callback) {
            overlayManager.hideOverlay();
            var $overlay = overlayManager.showOverlay({
                text: SN.Resources.SurveyList["AreYouSure"] + '</br><strong>' + title + '</strong> ?<div class="buttons"><span class="sn-button sn-submit ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only" id="DeleteQuestion">Delete</span><span class="sn-button sn-submit sn-button-cancel ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only" id="CancelDelete">Cancel</span></div>',
                cssClass: "popup-error",
                appendCloseButton: false
            });

            var $delete = $overlay.find("#DeleteQuestion");
            var $cancel = $overlay.find("#CancelDelete");
            $delete.on('click', function () { callback(sid, qid) });
            $cancel.on('click', overlayManager.hideOverlay);
        }

        function deleteSectionConfirmation(sid, callback) {
            var sectionTitle = $('#' + sid).find('input#textbox-title').first().val();
            overlayManager.hideOverlay();
            var $overlay = overlayManager.showOverlay({
                text: SN.Resources.SurveyList["AreYouSure"] + '</br><strong>' + sectionTitle + '</strong></br>' + SN.Resources.SurveyList["AndAllQuestion"] + ' ?<div class="buttons"><span class="sn-button sn-submit ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only" id="DeleteQuestion">Delete</span><span class="sn-button sn-submit sn-button-cancel ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only" id="CancelDelete">Cancel</span></div>',
                cssClass: "popup-error",
                appendCloseButton: false
            });

            var $delete = $overlay.find("#DeleteQuestion");
            var $cancel = $overlay.find("#CancelDelete");

            $delete.on('click', function () { callback(sid, saveDataToTextBox) });
            $cancel.on('click', overlayManager.hideOverlay);
        }

    };
    $.Survey.defaultOptions = {
    };
    $.fn.Survey = function (options) {
        return this.each(function () {
            var survey = new $.Survey(this, options);
            survey.init();
        });
    };
})(jQuery);
