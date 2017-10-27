// using $skin/scripts/sn/sn.fields.js

SN.Fields.DropDown = {
    name: 'dropdown',
    title: SN.Resources.SurveyList["DropdownQuestion-DisplayName"],
    icon: 'dropdown',
    editor: {
        schema: {
            fields: {
                Type: { type: "string", defaultValue: "Choice" },
                Control: { type: "string", defaultValue: "DropDown" },
                Id: { type: 'string' },
                Title: { type: "string", defaultValue: SN.Resources.SurveyList["UntitledQuestion"] },
                Hint: { type: "string" },
                //Required: { type: "boolean", defaultValue: false },
                Multiple: false,
                Jump: true,
                Other: false,
                Options: [],
                List: true,
                Settings: {
                    OtherValue: {
                        type: "checkbox",
                        defaultValue: false,
                        title: SN.Resources.SurveyList["OtherValue.html"],
                        template: SN.Templates.SurveyList["dropdownSettingsOtherValue.html"]
                    },
                    ListItem: {
                        title: SN.Resources.SurveyList["Option"],
                        index: 0,
                        template: SN.Templates.SurveyList["dropdownSettingsListItem.html"],
                        render: function (template, model) {
                            var itemTemplate = kendo.template(template);
                            return itemTemplate(model);
                        }
                    },
                    template: SN.Templates.SurveyList["dropdownSettings.html"],
                    render: function ($question, view) {
                        var $add = $question.find('.sn-survey-choicequestion-add span.add-option');
                        var $addOther = $question.find('.sn-survey-choicequestion-add span.add-other-option');
                        var $optionList = $question.find('ul.sn-survey-choicequestion-options');

                        var survey = $('#surveyContainer').data('Survey');
                        var template = SN.Fields.DropDown.fill.template;
                        var renderingFunction = SN.Fields.DropDown.fill.render;
                        var id = $question.closest('.sn-survey-section').attr('id');
                        var section = survey.getSectionById(id);
                        var questionId = $question.attr('id');
                        var question = survey.getQuestionById(section, questionId);

                        if (view === 'edit') {

                            if (question.Other)
                                $addOther.addClass('hidden');

                            $('.option-row .sn-icon-remove').on('click.optionRemove', function () {
                                var $option = $(this).closest('.option-row');
                                $option.remove();
                                save();
                                if ($option.hasClass('option-row-other'))
                                    $addOther.removeClass('hidden');
                                //reindex
                            });
                            $('.option-row div:first-of-type').on('click', function () {
                                var $title = $(this).find('input.option-title');
                                var $option = $(this).closest('.option-row');
                            });
                            $('.option-row .option-jumptosection select').on('focus', function () {
                                var $select = $(this);
                                buildSelect($select);
                            });
                        }

                        $add.off('click');
                        $add.on('click', function () {
                            var index = $optionList.children().length;
                            var other = $question.find('.option-row-other').length > 0;
                            if (other)
                                index -= 1;
                            var listItem = { title: SN.Resources.SurveyList["Option"], index: index, jumpto: -1 };
                            var item = SN.Fields.DropDown.editor.schema.fields.Settings.ListItem.render(SN.Fields.DropDown.editor.schema.fields.Settings.ListItem.template, listItem);
                            $optionList.append(item);
                            if (other)
                                $question.find('.option-row-other').appendTo($optionList);
                            $('.option-row .sn-icon-remove').off('click.optionRemove');
                            $('.option-row .sn-icon-remove').on('click.optionRemove', function () {
                                var $option = $(this).closest('.option-row');
                                $option.remove();
                                //reindex
                            });
                            $('.option-row div:first-of-type').on('click', function () {
                                var $title = $(this).find('input.option-title');
                                var $option = $(this).closest('.option-row');
                            });
                            $('.option-row .option-jumptosection select').on('focus', function () {
                                var $select = $(this);
                                buildSelect($select);
                            });

                            question = survey.getQuestionById(section, questionId);
                            save();
                            $question.find('input, select').on('input', save);
                            survey.refreshPreview(questionId, template, question, renderingFunction);
                        });
                        $addOther.on('click', function () {

                            question = survey.getQuestionById(section, questionId);
                            if (!$question.find('.option-row-other').length > 0) {
                                var index = $optionList.children().length;
                                var listItem = { title: SN.Resources.SurveyList["Other"], index: index, jumpto: -1 };
                                var item = SN.Fields.DropDown.editor.schema.fields.Settings.ListItem.render(SN.Fields.DropDown.editor.schema.fields.Settings.OtherValue.template, listItem);
                                $optionList.append(item)
                                $(this).addClass('hidden');
                                question.Other = true;
                                $('.option-row-other .sn-icon-remove').on('click.optionRemoveOther', function () {
                                    var $option = $(this).closest('.option-row');
                                    $option.remove();
                                    $addOther.removeClass('hidden');
                                    question.Other = false;
                                });
                                $('.option-row .option-jumptosection select').on('focus', function () {
                                    var $select = $(this);
                                    buildSelect($select);
                                });
                            }

                            save();
                            $question.find('input, select').on('input', save);
                            survey.refreshPreview(questionId, template, question, renderingFunction);
                        });

                        function buildSelect($select) {
                            $select.html('');
                            $select.append('<option value="">' + SN.Resources.SurveyList["GoToQuestion-Menu"] + '</option>');
                            var sections = survey.getSections();
                            var index = $('.sn-survey-section').index($question.closest('.sn-survey-section'));
                            for (var i = index; i < sections.length; i++) {
                                var option = $('<option value="' + sections[i].index + '">' + sections[i].title + '</option>').appendTo($select);
                            }
                            $select.on('change', function () {
                                question.Jump = true;
                            });
                        }

                        function save() {
                            var options = [];
                            for (var x = 0; x < $question.find('.option-row').length ; x++) {
                                var $option = $question.find('.sn-survey-choicequestion-options .option-row').eq(x);
                                var option = {};
                                option.title = $option.find('.option-title').val();
                                if (typeof option.title === 'undefined' || option.title.length === 0)
                                    option.title = $option.find('.option-title').text()
                                option.nextSectionIndex = $option.find('select option:selected').val();
                                options.push(option);
                            }
                            question = survey.getQuestionById(section, questionId);
                            question.Options = options;
                            question.Validation = SN.Fields.DropDown.editor.schema.fields.Validation;
                            survey.saveDataToTextBox();

                            var question = survey.getQuestionById(section, questionId);
                            survey.refreshPreview(questionId, template, question, renderingFunction);
                        }
                    }
                },
                Validation: {
                    Rule: { type: "string", value: "maxoptioncount" },
                    Value: { type: "string", index: 2, value: 1 }
                },
                SNFields: ['DisplayName', 'Description', 'Required', 'Options', 'AllowOtherChoice']
            }
        },
        template: SN.Templates.SurveyList["dropdownEditor.html"],
        menu: [
            { field: 'Hint', text: SN.Resources.SurveyList["Hint-Menu"] }
        ]
    },
    fill: {
        template: SN.Templates.SurveyList["dropdownFill.html"],
        render: function (id, mode, question) {
            var survey = $('#surveyContainer').data('Survey');
            if (typeof question !== 'undefined') {
                var options = question.Options;
                if (mode === 'editor') {
                    var section = survey.getSectionById($('#' + id).closest('.sn-survey-section').attr('id'));
                    question = survey.getQuestionById(section, id);
                    options = question.Options;
                }
                var $container = $('.sn-question[data-qid="' + id + '"]').find('.sn-survey-choicequestion-optioncontainer');
                if ($container.length === 0)
                    $container = $('.sn-survey-question#' + id).find('.sn-survey-choicequestion-optioncontainer');
                for (var i = 0; i < options.length; i++) {
                    var value = survey.encodeString(options[i].title);
                    var $option = $('<option data-next="' + options[i].nextSectionIndex + '" value="' + value + '">' + options[i].title + '</option>').appendTo($container);
                    if (i === 0)
                        $option.prop('selected', true).attr('selected', true);
                    if (question.Other && i === options.length - 1)
                        $option.addClass('other');

                }
                $container.on('change', function () {
                    var $this = $(this).find('option:selected');
                    if ($this.hasClass('other'))
                        $container.parent().append('<input type="text" name="other" />');
                    else
                        $container.parent().find('input[name=other]').remove();
                });
            }
        }
    }
}