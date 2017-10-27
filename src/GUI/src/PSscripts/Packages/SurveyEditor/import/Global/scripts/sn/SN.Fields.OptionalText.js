// using $skin/scripts/sn/sn.fields.js
// template SurveyEditor

SN.Fields.OptionalText = {
    name: 'optionaltext',
    title: SN.Resources.SurveyList["OptionalTextQuestion-DisplayName"],
    icon: 'optionaltext',
    editor: {
        //the editor tamplate of question
        schema: {
            fields: {
                // the editor parameters by question is invoked when created/edited
                Type: { type: "string", defaultValue: "OptionalText" },
                Control: { type: "string", defaultValue: "OptionalText" },
                Id: { type: 'string' },
                Title: { type: "string", defaultValue: SN.Resources.SurveyList["UntitledQuestion"] },
                Hint: { type: "string" },
                PlaceHolder: { type: "string" },
                Required: { type: "boolean", defaultValue: false },
                CustomRequired: { defaultValue: "optional-text-required" },
                Options: {
                    // choice option list
                    defaultValue: [
                    {
                        title: SN.Resources.SurveyList["YesValue"],
                        defaultValue: false,
                        value: SN.Resources.SurveyList["YesValue"],
                        text: ''
                    },
                    {
                        title: SN.Resources.SurveyList["NoValue"],
                        defaultValue: false,
                        value: SN.Resources.SurveyList["NoValue"]
                    }
                    ]
                },
                Settings: {
                    // functionality of question, that uses the filed-parameters defined above
                    template: SN.Templates.SurveyList["optionaltextSettings.html"],

                    render: function ($question) {
                        // create/edit question by default-and given values and functionality
                        var survey = $('#surveyContainer').data('Survey');
                        var template = SN.Fields.OptionalText.fill.template;
                        var renderingFunction = SN.Fields.OptionalText.fill.render;
                        var id = $question.closest('.sn-survey-section').attr('id');
                        var section = survey.getSectionById(id);
                        var questionId = $question.attr('id');
                        var question = survey.getQuestionById(section, questionId);

                        for (var i = 0; i < SN.Fields.OptionalText.editor.schema.fields.Options.defaultValue.length; i++) {
                            // render edit tamplate by the number and type of options
                            var option = SN.Fields.OptionalText.editor.schema.fields.Options.defaultValue[i];
                            var row = $('<li class="option-row"><input type="radio" disabled name="optionaltext"  id="' + option.value + '"  /><input type="text" class="option-title option-title-' + option.value + '" value="' + option.value + '"  id="' + option.value + '-title"/></li>').appendTo($question.find('.sn-survey-choicequestion-options'));
                            if (typeof option.text !== 'undefined')
                                row.append('<p class="optional-text-info">' + SN.Resources.SurveyList["OptionalTextInfo"] + '</p>');
                        }
                        $question.find('input, select').on('input', save);

                        // refresh preview after modifying data
                        setTimeout(function () {
                            survey.refreshPreview(questionId, template, question, renderingFunction);
                        }, 500)

                        function save() {
                            // push and save updated question-data to survey-related JSON
                            var options = [];
                            for (var x = 0; x < $question.find('.option-row').length; x++) {
                                var $option = $question.find('.sn-survey-choicequestion-options .option-row').eq(x);
                                var $textInput = $option.find('p');
                                var option = {};
                                option.title = $option.find('.option-title').val();
                                if (typeof option.title === 'undefined' || option.title.length === 0)
                                    option.title = $option.find('.option-title').text();
                                if ($textInput.length > 0)
                                    option.text = '';
                                options.push(option);
                            }
                            question = survey.getQuestionById(section, questionId);
                            question.Options = options;
                            survey.saveDataToTextBox();

                            var question = survey.getQuestionById(section, questionId);
                            survey.refreshPreview(questionId, template, question, renderingFunction);
                        }
                    }
                },
                Validation: {
                    // define validation parameters
                    Rule: { type: "string", value: "optional-text-required" },
                    Value: { type: "boolean", defaultValue: false }
                },
                // question related sn.fields
                SNFields: ['DisplayName', 'Description', 'Required', 'Options']
            },
            validation: {
                // custom validation if question is set to required
                fields: {
                    Type: [
                    {
                        // name, by it is used
                        name: 'validation',
                        // rule, that is used
                        rules: [
                        {
                            //rule-name, by validation is invoked
                            name: 'optional-text-required',
                            type: 'boolean',
                            snField: 'Required',
                            errorMessage: SN.Resources.SurveyList["OptionalTextRequired"],
                            method: function (e) {
                                // validation conditions
                                var $question = $(e).closest('.sn-question');
                                var validate = $question.attr('data-optional-text-required');

                                if (typeof validate !== 'undefined' && validate !== false) {
                                    var value = $question.find('input[type="radio"]:checked').length;
                                    if (value === 0)
                                        return false;
                                    else {
                                        for (var i = 0; i < value; i++) {
                                            var $option = $question.find('input[type="radio"]:checked').eq(i);
                                            var $textbox = $option.siblings('.option-text');
                                            if ($textbox.length !== 0) {
                                                if ($textbox.val().length > 0)
                                                    return true;
                                                else
                                                    return false;
                                            }
                                            else
                                                return true;
                                        }
                                    }
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
        // question editor markup
        template: SN.Templates.SurveyList["optionaltextEditor.html"],
        menu: [
            // question menu items
            { field: 'Hint', text: SN.Resources.SurveyList["Hint-Menu"] }
        ]
    },
    fill: {
        // question browse markup
        template: SN.Templates.SurveyList["optionaltextFill.html"],
        render: function (id, mode, question) {
            // render function to browse view
            var survey = $('#surveyContainer').data('Survey');
            var validator = survey.getValidator();
            if (typeof question !== 'undefined') {
                var options = question.Options;
                if (mode === 'editor') {
                    //render question preview in edit mode
                    var section = survey.getSectionById($('#' + id).closest('.sn-survey-section').attr('id'));
                    question = survey.getQuestionById(section, id);
                    options = question.Options;

                }

                var $container = $('.sn-question[data-qid="' + id + '"]').find('.sn-survey-choicequestion-optioncontainer');
                if ($container.length === 0)
                    $container = $('.sn-survey-question#' + id).find('.sn-survey-choicequestion-optioncontainer');
                for (var i = 0; i < options.length; i++) {
                    var value = survey.encodeString(options[i].title);
                    var $option = $('<li><input type="radio" value="' + value + '"><label>' + options[i].title + '</label></li>').appendTo($container);
                    if (typeof options[i].text !== 'undefined')
                        $option.append('<input class="option-text" type="text" />');
                }
            }

            // select option by completion
            $container.find('li').on('click', function () {
                var $this = $(this);
                var $radio = $this.find('input[type="radio"]');
                var $textInput = $this.find('input[type="text"]');
                $radio.prop('checked', true);
                $this.siblings().find('input[type="radio"]').prop('checked', false);
                var $siblingTextbox = $this.siblings().find('input[type="text"]');
                if ($radio.is(':checked') && $textInput.length === 0) {
                    $siblingTextbox.val('');
                    // TODO: if any radio is checked, remove global invalid msg
                }
                validator.validateInput($container);
            });
            $container.find('input[type="text"]').on('keyup', function () {
                validator.validateInput($container);
            });
        },

        // get value of answers, push and save them to survey related JSON
        value: function ($question, questionId) {
            var survey = $('#surveyContainer').data('Survey');
            var id = $question.closest('.sn-survey-section').attr('id');
            var section = survey.getSectionById(id);
            var question = survey.getQuestionById(section, questionId);
            var saveableData = '';

            var $checkedRadio = $question.find('input[type="radio"]:checked');
            var $textBox = $checkedRadio.siblings('input[type="text"]');
            saveableData = $checkedRadio.val();
            if ($textBox.length > 0)
                saveableData += ',' + $textBox.val();

            return saveableData;
        }
    }
}
