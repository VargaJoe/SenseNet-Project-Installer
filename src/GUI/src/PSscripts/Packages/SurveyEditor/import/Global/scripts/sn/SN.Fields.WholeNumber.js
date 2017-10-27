// using $skin/scripts/sn/sn.fields.js
// template SurveyList

SN.Fields.WholeNumber = {
    name: 'wholenumber',
    title: SN.Resources.SurveyList["WholeNumber"],
    icon: 'wholenumber',
    editor: {
        schema: {
            fields: {
                Type: { type: "string", defaultValue: "Number" },
                Control: { type: "string", defaultValue: "WholeNumber" },
                Id: { type: 'string' },
                Title: { type: "string", defaultValue: SN.Resources.SurveyList["UntitledQuestion"] },
                Hint: { type: "string" },
                PlaceHolder: { type: "string" },
                Required: { type: "boolean", defaultValue: false },
                Validation: {
                    Type: { type: "dropdown", index: 0 },
                    Rule: { type: "dropdown", cascadeFrom: 'Type', index: 1 },
                    Value: { type: "string", index: 2 },
                    ErrorMessage: { type: "string", index: 3, placeHolder: SN.Resources.SurveyList["ErrorMessage-PlaceHolder"] }
                },
                SNFields: [
                    { 'DisplayName': 'Title' },
                    { 'Description': 'Hint' },
                    { 'Compulsory': 'Required' },
                    { 'MaxValue': 'Validation' },
                    { 'MinValue': 'Validation' }]
            },
            validation: {
                fields: {
                    Type: [
                        {
                            name: 'wholenumber',
                            text: SN.Resources.SurveyList["WholeNumber"],
                            defaultValue: SN.Resources.SurveyList["WholeNumber"],
                            snFieldType: "WholeNumber",
                            rules: [
                                {
                                    name: 'maxvalue',
                                    text: SN.Resources.SurveyList["LessThan"],
                                    snField: 'MaxValue',
                                    type: 'number',
                                    value: true,
                                    method: function (e) {
                                        var validate = e.data('maxvalue');
                                        if (typeof validate !== 'undefined' && validate !== false && validate !== "") {
                                            var value = e.val();
                                            if (value === '')
                                                return true;
                                            else {
                                                var value = Number(e.val());
                                                var maxvalue = Number(e.attr('data-maxvalue-value'));
                                                return (value < maxvalue);
                                            }
                                        }
                                        return true;
                                    }
                                },
                                {
                                    name: 'minvalue',
                                    text: SN.Resources.SurveyList["GreaterThan"],
                                    snField: 'MinValue',
                                    type: 'number',
                                    value: true,
                                    method: function (e) {
                                        var validate = e.data('minvalue');
                                        if (typeof validate !== 'undefined' && validate !== false && validate !== "") {
                                            var value = e.val(); if (value === '')
                                                return true;
                                            else {
                                                var value = Number(e.val());
                                                var minvalue = Number(e.attr('data-minvalue-value'));
                                                return (value > minvalue);
                                            }
                                        }
                                        return true;
                                    }
                                },
                                 {
                                     name: 'between',
                                     text: SN.Resources.SurveyList["Between"],
                                     snField: ['MinValue', 'MaxValue'],
                                     type: 'number',
                                     method: function (e) {
                                         var validate = e.data('between');
                                         if (typeof validate !== 'undefined' && validate !== false && validate !== "") {
                                             var value = e.val(); if (value === '')
                                                 return true;
                                             else {
                                                 var value = Number(e.val());
                                                 var between = e.attr('data-between-value').split(',');
                                                 return ((Number(between[0]) < value) && (value < Number(between[1])));
                                             }
                                         }
                                         return true;
                                     }
                                 },
                                 {
                                     name: 'betweenand',
                                     text: SN.Resources.SurveyList["BetweenAnd"],
                                     snField: ['MinValue', 'MaxValue'],
                                     type: 'number',
                                     method: function (e) {
                                         var validate = e.data('betweenand');
                                         if (typeof validate !== 'undefined' && validate !== false && validate !== "") {
                                             var value = e.val();
                                             if (value === '')
                                                 return true;
                                             else {
                                                 var value = Number(e.val());
                                                 var between = e.attr('data-betweenand-value').split(',');
                                                 return ((Number(between[0]) <= value) && (value <= Number(between[1])));
                                             }
                                         }
                                         return true;
                                     }
                                 }
                            ]
                        },
                        {
                            name: 'regexp',
                            text: SN.Resources.SurveyList["RegExp"],
                            defaultValue: SN.Resources.SurveyList["Pattern"],
                            snFieldType: "ShortText",
                            rules: [
                                {
                                    name: 'regexmatches',
                                    text: SN.Resources.SurveyList["Matches"],
                                    snField: "Regex",
                                    type: 'string',
                                    method: function (e) {
                                        var validate = e.data('regexmatches');
                                        if (typeof validate !== 'undefined' && validate !== false && validate !== "") {
                                            var value = e.val();
                                            if (value === '')
                                                return true;
                                            else {
                                                var inputstring = e.attr('data-regexmatches-value');
                                                var flags = inputstring.replace(/.*\/([gimy]*)$/, '$1');
                                                var pattern = inputstring.replace(new RegExp('^/(.*?)/' + flags + '$'), '$1');
                                                var regex = new RegExp(pattern, flags);
                                                return regex.test(value);
                                            }
                                        }
                                        return true;
                                    }
                                },
                                {
                                    name: 'regexdoesntmatches',
                                    text: SN.Resources.SurveyList["DoesntMatch"],
                                    snField: "Regex",
                                    type: 'string',
                                    method: function (e) {
                                        var validate = e.data('regexdoesntmatches');
                                        if (typeof validate !== 'undefined' && validate !== false && validate !== "") {
                                            var value = e.val(); if (value === '')
                                                return true;
                                            else {
                                                var inputstring = e.attr('data-regexdoesntmatches-value');
                                                var flags = inputstring.replace(/.*\/([gimy]*)$/, '$1');
                                                var pattern = inputstring.replace(new RegExp('^/(.*?)/' + flags + '$'), '$1');
                                                var regex = new RegExp(pattern, flags);
                                                return !regex.test(value);
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
        template: SN.Templates.SurveyList["wholenumberEditor.html"],
        menu: [
            { field: 'Hint', text: SN.Resources.SurveyList["Hint-Menu"] },
            { field: 'PlaceHolder', text: SN.Resources.SurveyList["PlaceHolder-Menu"] },
            { field: 'Validation', text: SN.Resources.SurveyList["Validation-Menu"] }
        ]
    },
    fill: {
        template: SN.Templates.SurveyList["wholenumberFill.html"]
    }
}