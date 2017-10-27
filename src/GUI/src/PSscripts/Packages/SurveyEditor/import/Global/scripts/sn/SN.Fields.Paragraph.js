// using $skin/scripts/sn/sn.fields.js
// template SurveyList

SN.Fields.Paragraph = {
    name: 'long',
    title: SN.Resources.SurveyList["LongQuestion-DisplayName"],
    icon: 'long',
    editor: {
        schema: {
            fields: {
                Type: { type: "string", defaultValue: "LongText" },
                Control: { type: "string", defaultValue: "Paragraph" },
                Id: { type: 'string' },
                Title: { type: "string", defaultValue: SN.Resources.SurveyList["UntitledQuestion"] },
                Hint: { type: "string" },
                PlaceHolder: { type: "string" },
                Required: { type: "boolean", defaultValue: false },
                Validation: {
                    Rule: { type: "dropdown", index: 0 },
                    Value: { type: "string", index: 1 },
                    ErrorMessage: { type: "string", index: 2, placeHolder: SN.Resources.SurveyList["ErrorMessage-PlaceHolder"] }
                },
                SNFields: ['DisplayName', 'Description', 'Required', 'MinLength', 'MaxLength']
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
                                }
                            ]
                        }
                    ]
                }
            }
        },
        template: SN.Templates.SurveyList["paragraphEditor.html"],
        menu: [
            { field: 'Hint', text: SN.Resources.SurveyList["Hint-Menu"] },
            { field: 'PlaceHolder', text: SN.Resources.SurveyList["PlaceHolder-Menu"] },
            { field: 'Validation', text: SN.Resources.SurveyList["Validation-Menu"] }
        ]
    },
    fill: {
        template: SN.Templates.SurveyList["paragraphFill.html"]
    }
}