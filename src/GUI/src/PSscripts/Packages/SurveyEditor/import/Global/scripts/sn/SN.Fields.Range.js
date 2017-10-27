// using $skin/scripts/sn/sn.fields.js
// template SurveyList

SN.Fields.Range = {
    name: 'range',
    title: SN.Resources.SurveyList["RangeQuestion-DisplayName"],
    icon: 'range',
    editor: {
        schema: {
            fields: {
                Type: { type: "string", defaultValue: "Range" },
                Id: { type: 'string' },
                Title: { type: "string", defaultValue: SN.Resources.SurveyList["UntitledQuestion"] },
                Hint: { type: "string" },
                PlaceHolder: { type: "string" },
                Settings: {
                    MinValue: {
                        defaultValue: 1,
                        type: 'number',
                        title: SN.Resources.SurveyList["MinValue"]
                    },
                    MaxValue: {
                        defaultValue: 10,
                        type: 'number',
                        title: SN.Resources.SurveyList["MaxValue"]
                    },
                    Step: {
                        defaultValue: 1,
                        type: 'number',
                        title: SN.Resources.SurveyList["Step"]
                    },
                    template: SN.Templates.SurveyList["rangeSettings.html"],
                    render: function ($question) {
                        var $settingsRow = $question.find('.sn-survey-question-inner');
                        var timeoutId;
                        $settingsRow.find('input').on('input', function () {
                            var $this = $(this);
                            clearTimeout(timeoutId);
                            timeoutId = setTimeout(function () {
                                var min = $settingsRow.find('#MinValue').val() || MaxValue.defaultValue;
                                max = $settingsRow.find('#MaxValue').val() || MinValue.defaultValue;
                                step = $settingsRow.find('#Step').val() || Step.defaultValue;
                                var $error = $this.siblings('span.error');
                                $(document).off('click.Focus');
                                $this.blur();

                                if (SN.Fields.Range.editor.schema.fields.Settings.validation([min, max, step])) {
                                    var $slider = $question.find('input.sn-range').data("kendoSlider");
                                    $error.addClass('hidden');
                                    //if (typeof $slider !== 'undefined' && $slider)
                                    //    $slider.destroy();
                                    //$question.find('input.sn-range').closest(".k-slider").remove();

                                }
                                else {
                                    if (Number(min) > Number(max)) {
                                        $error.removeClass('hidden').text(SN.Resources.SurveyList["MinIsGreaterThanMaxErrorMessage"]);
                                        $(document).on('click.Focus', function () {
                                            $this.focus();
                                        });
                                    }
                                    else if (((Number(max) - Number(min)) % Number(step)) > 0) {
                                        $error.removeClass('hidden').text(SN.Resources.SurveyList["StepIsNotCorrectErrorMessage"]);
                                        $(document).on('click.Focus', function () {
                                            $this.focus();
                                        });
                                    }
                                }
                            }, 500);
                        });
                    },
                    validation: function (settings) {
                        var valid = true;
                        var min = Number(settings[0]);
                        var max = Number(settings[1]);
                        var step = Number(settings[2]);
                        if (min > max) {
                            valid = false;
                        }
                        else if (((max - min) % step) > 0) {
                            valid = false;
                        }
                        return valid;
                    }
                },
                SNFields: ['DisplayName', 'Description', 'Required', 'MaxValue', 'MinValue', 'Step']
            }
        },
        template: SN.Templates.SurveyList["rangeEditor.html"],
        menu: [
            { field: 'Hint', text: SN.Resources.SurveyList["Hint-Menu"] }
        ]
    },
    fill: {
        template: SN.Templates.SurveyList["rangeFill.html"],
        render: function (id, mode, question) {
            var $input = $('[data-qid="' + id + '"]').find('.sn-range');
            if (mode === 'editor')
                $input = $('#' + id).find('.sn-range');
            var max, min, step;
            var settings = question.Settings;
            if (typeof settings === 'undefined')
                settings = question.editor.schema.fields.Settings;
            if (typeof question !== 'undefined' && typeof settings !== 'undefined') {
                max = Number(settings.MaxValue.value || settings.MaxValue.defaultValue);
                min = Number(settings.MinValue.value || settings.MinValue.defaultValue);
                step = Number(settings.Step.value || settings.Step.defaultValue);
            }
            else {
                max = Number(MaxValue.value) || Number(MaxValue.defaultValue);
                min = Number(MinValue.value) || Number(MinValue.defaultValue);
                step = Number(Step.value) || Number(Step.defaultValue);
            }

            var $slider = $input.data("kendoSlider");
            if (typeof $slider !== 'undefined') {
                $input.data("kendoSlider").destroy();
                $input.closest(".k-slider").remove();
            }
            var input = $input.kendoSlider({
                increaseButtonTitle: "Right",
                decreaseButtonTitle: "Left",
                min: min,
                max: max,
                value: step,
                largeStep: step,
                smallStep: step,
                showButtons: false,
            }).data("kendoSlider");
            var width = ($('.sn-survey-section').first().outerWidth() - 40) * 0.3;
            input.wrapper.css({ "width": width + 'px' });
            if (mode === 'editor') {
                input.wrapper.css({ "width": "30%" });
                input.disable();
                //$('#' + id).find('.sn-survey-question-elements').css("min-height", "50px");
            }
            input.resize();
        }
    }
}