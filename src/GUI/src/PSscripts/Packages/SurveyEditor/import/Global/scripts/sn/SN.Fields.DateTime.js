// using $skin/scripts/sn/sn.fields.js
// using $skin/scripts/moment/moment.min.js
// template SurveyList

SN.Fields.DateTime = {
    name: 'date',
    title: SN.Resources.SurveyList["DateQuestion-DisplayName"],
    icon: 'date',
    editor: {
        schema: {
            fields: {
                Type: { type: "string", defaultValue: "DateTime" },
                Id: { type: 'string' },
                Title: { type: "string", defaultValue: SN.Resources.SurveyList["UntitledQuestion"] },
                Hint: { type: "string" },
                PlaceHolder: { type: "string" },
                Required: { type: "boolean", defaultValue: false },
                Validation: {
                    Type: { type: "dropdown", index: 0 },
                    Rule: { type: "dropdown", cascadeFrom: 'Type', index: 1 },
                    Value: { type: "string", index: 1 },
                    ErrorMessage: { type: "string", index: 2, placeHolder: SN.Resources.SurveyList["ErrorMessage-PlaceHolder"] }
                },
                SNFields: ['DisplayName', 'Description', 'Required']
            },
            validation: {
                fields: {
                    Type: [
                        {
                            name: 'dateonly',
                            text: SN.Resources.SurveyList["DateOnly"],
                            defaultValue: SN.Resources.SurveyList["DateOnly"],
                            snFieldType: "DateTime",
                            rules: [
                                {
                                    name: 'mindate',
                                    text: SN.Resources.SurveyList["MinDate"],
                                    value: true,
                                    type: 'date',
                                    method: function (e) {
                                        var validate = e.data('mindate');
                                        if (typeof validate !== 'undefined' && validate !== false) {
                                            var value = e.val();
                                            if (value === '')
                                                return true;
                                            var mindate = e.attr('data-mindate-value');
                                            var pattern = /(\d{2})\.(\d{2})\.(\d{4})/;
                                            var dt = new Date(value.replace(pattern, '$3-$2-$1'));
                                            var dt2 = new Date(mindate.replace(pattern, '$3-$2-$1'));
                                            return (dt.getTime() >= dt2.getTime());
                                        }
                                        return true;
                                    }
                                },
                                {
                                    name: 'maxdate',
                                    text: SN.Resources.SurveyList["MaxDate"],
                                    value: true,
                                    type: 'date',
                                    method: function (e) {
                                        var validate = e.data('maxdate');
                                        if (typeof validate !== 'undefined' && validate !== false) {
                                            var value = e.val();
                                            if (value === '')
                                                return true;
                                            var maxdate = e.attr('data-maxdate-value');
                                            var pattern = /(\d{2})\.(\d{2})\.(\d{4})/;
                                            var dt = new Date(value.replace(pattern, '$3-$2-$1'));
                                            var dt2 = new Date(maxdate.replace(pattern, '$3-$2-$1'));
                                            return (dt.getTime() <= dt2.getTime());
                                        }
                                        return true;
                                    }
                                },
                                {
                                    name: 'betweendate',
                                    text: SN.Resources.SurveyList["BetweenDate"],
                                    snField: ['MinDate', 'MaxDate'],
                                    type: 'date',
                                    method: function (e) {
                                        var validate = e.data('betweendate');
                                        if (typeof validate !== 'undefined' && validate !== false) {
                                            var value = e.val(); if (value === '')
                                                return true;
                                            else {
                                                var value = e.val();
                                                if (value === '')
                                                    return true;
                                                var between = decodeURIComponent(e.attr('data-betweendate-value').replace(/\%2D/g, "-").replace(/\%5F/g, "_").replace(/\%2E/g, ".").replace(/\%21/g, "!").replace(/\%7E/g, "~").replace(/\%2A/g, "*").replace(/\%27/g, "'").replace(/\%28/g, "(").replace(/\%29/g, ")")).split(',');
                                                var pattern = /(\d{2})\.(\d{2})\.(\d{4})/;
                                                var dt = new Date(value.replace(pattern, '$3-$2-$1'));
                                                var dt2 = new Date(between[0].replace(pattern, '$3-$2-$1'));
                                                var dt3 = new Date(between[1].replace(pattern, '$3-$2-$1'));
                                                return ((dt2.getTime() < dt.getTime()) && (dt.getTime() < dt3.getTime()));
                                            }
                                        }
                                        return true;
                                    }
                                }
                            ]
                        },
                        {
                            name: 'timeonly',
                            text: SN.Resources.SurveyList["TimeOnly"],
                            defaultValue: SN.Resources.SurveyList["TimeOnly"],
                            snFieldType: "DateTime",
                            rules: [
                                {
                                    name: 'mintime',
                                    text: SN.Resources.SurveyList["MinTime"],
                                    value: true,
                                    type: 'time',
                                    method: function (e) {
                                        var validate = e.data('mintime');
                                        if (typeof validate !== 'undefined' && validate !== false) {
                                            var value = e.val().split(':');
                                            if (value === '')
                                                return true;
                                            var numValue = Number(value[0] + value[1]);
                                            var mindate = e.attr('data-mintime-value').split(':');
                                            var numMinDate = Number(mindate[0] + mindate[1]);
                                            return (numValue >= numMinDate);
                                        }
                                        return true;
                                    }
                                },
                                {
                                    name: 'maxtime',
                                    text: SN.Resources.SurveyList["MaxTime"],
                                    value: true,
                                    type: 'time',
                                    method: function (e) {
                                        var validate = e.data('maxtime');
                                        if (typeof validate !== 'undefined' && validate !== false) {
                                            var value = e.val().split(':');
                                            if (value === '')
                                                return true;
                                            var numValue = Number(value[0] + value[1]);
                                            var maxtime = e.attr('data-maxtime-value').split(':');
                                            var numMaxDate = Number(maxtime[0] + maxtime[1]);
                                            return (numValue <= numMaxDate);
                                        }
                                        return true;
                                    }
                                },
                                {
                                    name: 'betweentime',
                                    text: SN.Resources.SurveyList["BetweenTime"],
                                    snField: ['MinTime', 'MaxTime'],
                                    type: 'time',
                                    method: function (e) {
                                        var validate = e.data('betweentime');
                                        if (typeof validate !== 'undefined' && validate !== false) {
                                            var value = e.val(); if (value === '')
                                                return true;
                                            else {
                                                var value = e.val().split(':');
                                                var numValue = Number(value[0] + value[1]);
                                                var between = decodeURIComponent(e.attr('data-betweentime-value').replace(/\%2D/g, "-").replace(/\%5F/g, "_").replace(/\%2E/g, ".").replace(/\%21/g, "!").replace(/\%7E/g, "~").replace(/\%2A/g, "*").replace(/\%27/g, "'").replace(/\%28/g, "(").replace(/\%29/g, ")")).split(',');
                                                var betweenMin = between[0].split(':');
                                                var betweenMax = between[1].split(':');
                                                var min = Number(betweenMin[0] + betweenMin[1]);
                                                var max = Number(betweenMax[0] + betweenMax[1]);
                                                return ((min <= numValue) && (numValue <= max));
                                            }
                                        }
                                        return true;
                                    }
                                }
                            ]
                        },
                        {
                            name: 'dateandtime',
                            text: SN.Resources.SurveyList["DateAndTime"],
                            defaultValue: SN.Resources.SurveyList["DateAndTime"],
                            snFieldType: "DateTime",
                            rules: [
                                {
                                    name: 'mindateandtime',
                                    text: SN.Resources.SurveyList["MinDateAndTime"],
                                    value: true,
                                    type: 'dateandtime',
                                    method: function (e) {
                                        var validate = e.data('mindateandtime');
                                        if (typeof validate !== 'undefined' && validate !== false) {
                                            var value = e.val();
                                            if (value === '')
                                                return true;
                                            var mindateandtime = e.attr('data-mindateandtime-value');
                                            var dt = new Date(value);
                                            var dt2 = new Date(mindateandtime);
                                            return (dt.getTime() >= dt2.getTime());
                                        }
                                        return true;
                                    }
                                },
                                {
                                    name: 'maxdateandtime',
                                    text: SN.Resources.SurveyList["MaxDateAndTime"],
                                    value: true,
                                    type: 'dateandtime',
                                    method: function (e) {
                                        var validate = e.data('maxdateandtime');
                                        if (typeof validate !== 'undefined' && validate !== false) {
                                            var value = e.val();
                                            if (value === '')
                                                return true;
                                            var maxdateandtime = e.attr('data-maxdateandtime-value');
                                            var dt = new Date(value);
                                            var dt2 = new Date(maxdateandtime);
                                            return (dt.getTime() <= dt2.getTime());
                                        }
                                        return true;
                                    }
                                },
                                {
                                    name: 'betweendateandtime',
                                    text: SN.Resources.SurveyList["BetweenDateAndTime"],
                                    snField: ['MinDateTime', 'MaxDateTime'],
                                    type: 'dateandtime',
                                    method: function (e) {
                                        var validate = e.data('betweendateandtime');
                                        if (typeof validate !== 'undefined' && validate !== false) {
                                            var value = e.val(); if (value === '')
                                                return true;
                                            else {
                                                var value = e.val();
                                                var between = decodeURIComponent(e.attr('data-betweendateandtime-value').replace(/\%2D/g, "-").replace(/\%5F/g, "_").replace(/\%2E/g, ".").replace(/\%21/g, "!").replace(/\%7E/g, "~").replace(/\%2A/g, "*").replace(/\%27/g, "'").replace(/\%28/g, "(").replace(/\%29/g, ")")).split(',');
                                                var betweenMin = between[0];
                                                var betweenMax = between[1];
                                                var dt = new Date(value);
                                                var dt2 = new Date(betweenMin);
                                                var dt3 = new Date(betweenMax);
                                                return ((dt2.getTime() <= dt.getTime()) && (dt.getTime() <= dt3.getTime()));
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
        template: SN.Templates.SurveyList["datetimeEditor.html"],
        menu: [
            { field: 'Hint', text: SN.Resources.SurveyList["Hint-Menu"] },
            { field: 'PlaceHolder', text: SN.Resources.SurveyList["PlaceHolder-Menu"] },
            { field: 'Validation', text: SN.Resources.SurveyList["Validation-Menu"] }
        ]
    },
    fill: {
        template: SN.Templates.SurveyList["datetimeFill.html"],
        render: function (id, mode) {
            var $input = $('.sn-question[data-qid="' + id + '"]').find('input');
            var survey = $('#surveyContainer').data('Survey');
            var validator = survey.getValidator();
            if (mode === 'editor')
                $input = $('.sn-survey-question#' + id).find('.sn-survey-question-elements').find('input');
            var type = $input.attr('data-type');
            switch (type) {
                case 'date':
                    $input.kendoDatePicker({
                        close: validation
                    });
                    break;
                case 'dateandtime':
                    $input.kendoDateTimePicker({
                        timeFormat: "HH:mm",
                        format: "yyyy-MM-dd HH:mm",
                        parseFormats: ["yyyy-MM-dd HH:mm", "HH:mm"],
                        close: validation
                    });
                    break;
                case 'time':
                    $input.kendoTimePicker({
                        format: 'HH:mm',
                        close: validation
                    });
                    break;
                default:
                    $input.kendoDatePicker({
                        close: validation
                    });
                    break;
            }

            function validation() {
                validator.validateInput($input)
            }
        },
        value: function ($question, questionId) {
            var $input = $question.find('input[type="text"]');
            if ($input.val().length > 0)
                return moment($input.val()).format();
            else
                return null;
        }
    }
}