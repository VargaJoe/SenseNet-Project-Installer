// using $skin/scripts/sn/sn.fields.js
// template SurveyEditor

SN.Fields.Switch = {
        name: 'switch',
        title: SN.Resources.SurveyList["SwitchQuestion-DisplayName"],
        icon: 'switch',
        editor: {
        schema: {
                    fields: {
                    Type: { type: "string", defaultValue: "Boolean" },
                    Id: { type: 'string' },
                    Title: { type: "string", defaultValue: SN.Resources.SurveyList["UntitledQuestion"] },
                    Hint: { type: "string" },
                    Required: { type: "boolean", defaultValue: false },
                    SNFields: ['DisplayName', 'Description', 'Required']
                    }
        },
            template: SN.Templates.SurveyList["switchEditor.html"],
            menu: [
                { field: 'Hint', text: SN.Resources.SurveyList["Hint-Menu"] },
            ]
        },
    fill: {
            template: SN.Templates.SurveyList["switchFill.html"],
            render: function (id) {
                var $input = $('div[data-qid="' + id + '"]').find('.onoffswitch');
                $input.on('click', function () {
                    var $checkbox = $input.find('input');
                    if ($checkbox.is(':checked'))
                        $checkbox.prop('checked', false).attr('checked', false);
                    else
                        $checkbox.prop('checked', true).attr('checked', true);
                });
            }
    }
}