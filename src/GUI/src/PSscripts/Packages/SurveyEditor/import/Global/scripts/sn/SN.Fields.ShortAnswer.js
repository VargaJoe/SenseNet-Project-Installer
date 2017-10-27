// using $skin/scripts/sn/sn.fields.js
// template SurveyList

SN.Fields.ShortAnswer = {
    name: 'short',
    title: SN.Resources.SurveyList["ShortQuestion-DisplayName"],
    icon: 'short',
    editor: {
        schema: {
            fields: {
                Type: { type: "string", defaultValue: "ShortText" },
                Control: { type: "string", defaultValue: "ShortAnswer" },
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
                    { 'MinValue': 'Validation' },
                    { 'MinLength': 'Validation' },
                    { 'MaxLength': 'Validation' },
                    { 'Regex': 'Validation' }]
            },
            validation: {
                fields: {
                    Type: [
                        {
                            name: 'text',
                            text: SN.Resources.SurveyList["Text"],
                            defaultValue: SN.Resources.SurveyList["Text"],
                            snFieldType: "ShortText",
                            rules: [
                                {
                                    name: 'minlength',
                                    text: SN.Resources.SurveyList["MinLength"],
                                    value: true,
                                    snField: 'MinLength',
                                    type: 'number',
                                    method: function (e) {
                                        var validate = e.data('minlength');
                                        if (typeof validate !== 'undefined' && validate !== false && validate !== "") {
                                            var value = e.val();
                                            var minlength = Number(e.attr('data-minlength-value'));
                                            return (value.length >= minlength);
                                        }
                                        return true;
                                    }
                                },
                                {
                                    name: 'maxlength',
                                    text: SN.Resources.SurveyList["MaxLength"],
                                    value: true,
                                    snField: 'MaxLength',
                                    type: 'number',
                                    method: function (e) {
                                        var validate = e.data('maxlength');
                                        if (typeof validate !== 'undefined' && validate !== false && validate !== "") {
                                            var value = e.val();
                                            var maxlength = Number(e.attr('data-maxlength-value'));
                                            return (value.length <= maxlength);
                                        }
                                        return true;
                                    }
                                },
                                {
                                    name: 'emailaddress',
                                    text: SN.Resources.SurveyList["Email"],
                                    pattern: '/^[+a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/i',
                                    value: false,
                                    snField: 'Regex',
                                    type: 'string',
                                    method: function (e) {
                                        var validate = e.data('emailaddress');
                                        if (typeof validate !== 'undefined' && validate !== false && e.attr('sn-pattern') !== "") {
                                            var value = e.val();
                                            if (value === '')
                                                return true;
                                            else {
                                                var inputstring = e.attr('sn-pattern');
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
                                    name: 'urladdress',
                                    text: SN.Resources.SurveyList["Url"],
                                    pattern: '/(^|\s)((https?:\/\/)?[\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?)/gi',
                                    value: false,
                                    snField: 'Regex',
                                    type: 'string',
                                    method: function (e) {
                                        var validate = e.data('urladdress');
                                        if (typeof validate !== 'undefined' && validate !== false && validate !== "") {
                                            var value = e.val(); if (value === '')
                                                return true;
                                            else {
                                                var urlPattern = new RegExp(/(^|\s)((https?:\/\/)?[\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?)/gi)
                                                return urlPattern.test(value);
                                            }
                                        }
                                        return true;
                                    }
                                }
                            ]
                        },
                        {
                            name: 'number',
                            text: SN.Resources.SurveyList["Number"],
                            defaultValue: SN.Resources.SurveyList["Number"],
                            snFieldType: "Number",
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
                                            var value = e.val();
                                            if (value === '')
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
                                            var value = e.val();
                                            if (value === '')
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
                                                var between = e.attr('data-between-value').split(',');
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
                                        var validate = e.data('regexmatches-value');
                                        if (typeof validate !== 'undefined' && validate !== false && validate !== "") {
                                            var value = e.val();
                                            if (value === '')
                                                return true;
                                            else {
                                                var inputstring = e.attr('data-regexmatches-value');
                                                var string = '/' + inputstring + '/i';
                                                var flags = string.replace(/.*\/([gimy]*)$/, '$1');
                                                pattern = string.replace(new RegExp('^/(.*?)/' + flags + '$'), '$1');
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
                                        var validate = e.data('regexdoesntmatches-value');
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
        template: SN.Templates.SurveyList["shortanswerEditor.html"],
        menu: [
            { field: 'Hint', text: SN.Resources.SurveyList["Hint-Menu"] },
            { field: 'PlaceHolder', text: SN.Resources.SurveyList["PlaceHolder-Menu"] },
            { field: 'Validation', text: SN.Resources.SurveyList["Validation-Menu"] }
        ]
    },
    fill: {
        template: SN.Templates.SurveyList["shortanswerFill.html"],
        schema: function (e) {
            var type = e.attr('type');
            if (type === 'number')
                return Number(e.val());
            else
                return e.val();
        }
    }
}
