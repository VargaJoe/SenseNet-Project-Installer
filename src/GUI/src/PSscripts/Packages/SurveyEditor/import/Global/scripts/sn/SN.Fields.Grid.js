// using $skin/scripts/sn/sn.fields.js
// template SurveyList

SN.Fields.Grid = {
    name: 'grid',
    title: SN.Resources.SurveyList["GridQuestion-DisplayName"],
    icon: 'grid',
    editor: {
        schema: {
            fields: {
                Type: { type: "string", defaultValue: "Grid" },
                Id: { type: 'string' },
                Title: { type: "string", defaultValue: SN.Resources.SurveyList["UntitledQuestion"] },
                Hint: { type: "string" },
                Required: { type: "boolean", defaultValue: false },
                CustomRequired: {type: "string", defaultValue: "grid-required"},
                List: true,
                GridSchema: {
                    rows: [
                        {
                            title: SN.Resources.SurveyList["UntitledRow"],
                            index: 0,
                            type: 'radio'
                        }
                    ],
                    columns: [
                        {
                            title: SN.Resources.SurveyList["UntitledColumn"],
                            index: 0
                        },
                        {
                            title: SN.Resources.SurveyList["UntitledColumn"],
                            index: 1
                        }
                    ]
                },
                Settings: {
                    template: SN.Templates.SurveyList["gridSettings.html"],
                    render: function ($question, view) {
                        var $grid = $question.find('.sn-survey-gridquestion-table');
                        var id = $question.closest('.sn-survey-section').attr('id');
                        var survey = $('#surveyContainer').data('Survey');
                        var template = SN.Fields.Grid.fill.template;
                        var renderingFunction = SN.Fields.Grid.fill.render;
                        var section = survey.getSectionById(id);
                        var questionId = $question.attr('id');
                        var question = survey.getQuestionById(section, questionId);
                        if (view === 'new' || (view === 'edit' && question.GridSchema.length === 0))
                            question.GridSchema = $.extend(true, {}, SN.Fields.Grid.editor.schema.fields.GridSchema);

                        createGrid();

                        setTimeout(function () {
                            survey.refreshPreview(questionId, template, question, renderingFunction);
                        }, 500)

                        function changeRowTypes(e) {
                            var item = this.dataItem(e.item.index());
                            var value = item.Icon;
                            var $dd = $(e.sender.element);
                            var id = $dd.closest('.sn-survey-section').attr('id');
                            var section = survey.getSectionById(id);
                            var questionId = $dd.closest('.sn-survey-question').attr('id');
                            var q = survey.getQuestionById(section, questionId);
                            var $grid = $dd.closest('.k-grid').find('table.sn-survey-gridquestion-table');
                            for (var i = 0; i < q.GridSchema.rows.length; i++)
                                q.GridSchema.rows[i]["type"] = value;

                            survey.saveDataToTextBox();
                            refreshGrid($grid);
                        }
                        function createDataFromGridSchema() {
                            var data = {};
                            data.dataSource = [];
                            data.fields = {};
                            data.columns = [];
                            for (var i = 0; i < question.GridSchema.rows.length; i++) {
                                var item = question.GridSchema.rows[i];
                                var row = {};
                                var template;
                                row.Title = item.title;
                                row.Index = item.index;
                                row.Type = item.type;

                                data.dataSource.push(row);
                            }

                            data.fields.Title = { type: "string" };

                            var gridButtons = {
                                addrow: SN.Resources.SurveyList["AddRow"],
                                addcolumn: SN.Resources.SurveyList["AddColumn"]
                            }
                            var headerTemplate = kendo.template(SN.Templates.SurveyList["gridSettingsFirstColumnHeader.html"]);
                            var templatedHeader = headerTemplate(gridButtons);

                            data.columns.push({
                                field: "Title",
                                headerTemplate: templatedHeader,
                                template: SN.Templates.SurveyList["gridSettingsColumn.html"],
                                locked: true,
                                width: 250
                            });
                            for (var j = 0; j < question.GridSchema.columns.length; j++) {
                                var column = question.GridSchema.columns[j];
                                if (item.type === 'text') {
                                    row['field-' + column.index] = '';
                                    data.fields['field-' + column.index] = { type: "string" }
                                }
                                else if (item.type === 'radio' && column.index === 0) {
                                    row['field-' + column.index] = true;
                                    data.fields['field-' + column.index] = { type: "string" };
                                }
                                else {
                                    row['field-' + column.index] = false;
                                    data.fields['field-' + column.index] = { type: "string" };
                                }
                                
                                var columnTitleText = {
                                    columntitle : column.title
                                }

                                var gridSettingsColumnHeaderTemplate = kendo.template(SN.Templates.SurveyList["gridSettingsColumnHeader.html"]);
                                var templatedGridColumnHeader = gridSettingsColumnHeaderTemplate(columnTitleText);

                                data.columns.push({
                                    field: 'field-' + column.index,
                                    title: column.title,
                                    headerTemplate: templatedGridColumnHeader,
                                    template: function (e) {
                                        return '<input disabled type="' + e.Type + '" />'
                                    },
                                    lockable: false,
                                    width: 150
                                });
                            }
                            return data;
                        }
                        function changeRowProperty(grid, index, property, value) {
                            question.GridSchema.rows[index][property] = value;
                            survey.saveDataToTextBox();
                            survey.refreshPreview(questionId, template, question, renderingFunction);
                            //refreshGrid(grid);
                        }
                        function changeColumnTitle(grid, index, property, value) {
                            question.GridSchema.columns[index][property] = value;
                            survey.saveDataToTextBox();
                            survey.refreshPreview(questionId, template, question, renderingFunction);
                            //refreshGrid(grid);
                        }
                        function createGrid() {
                            var data = createDataFromGridSchema();
                            var width = $grid.closest('.sn-survey-question-inner').width() - 20;
                            var height = (question.GridSchema.rows.length + 1) * 53;
                            var type = question.GridSchema.rows[0].type;
                            if (question.GridSchema.columns.length > 4)
                                height += 25;
                            $grid.kendoGrid({
                                dataSource: {
                                    data: data.dataSource,
                                    schema: {
                                        model: {
                                            fields: data.fields
                                        }
                                    }
                                },
                                scrollable: true,
                                sortable: false,
                                filterable: false,
                                pageable: false,
                                resizable: true,
                                //reorderable: true,
                                columns: data.columns,
                                dataBound: function (e) {
                                    $(this.element).closest('.k-grid').find("span#rowTypeChooser").kendoDropDownList({
                                        dataTextField: "",
                                        dataValueField: "Icon",
                                        dataSource: [
                                            { Icon: 'radio' },
                                            { Icon: 'checkbox' },
                                            { Icon: 'text' }
                                        ],
                                        valueTemplate: '<span class="fa sn-icon sn-icon-#: data.Icon#"></span>',
                                        template: '<span class="fa sn-icon sn-icon-#: data.Icon#"></span>',
                                        index: 0,
                                        select: changeRowTypes,
                                        value: type
                                    });
                                    var timeoutId;
                                    $question.find('table input[type="text"]').on('keyup', function () {
                                        var $this = $(this);
                                        clearTimeout(timeoutId);
                                        timeoutId = setTimeout(function () {
                                            var value = $this.val();
                                            var rowIndex = $this.closest('tr').index();
                                            var columnIndex = $this.closest('th').index();
                                            var grid = $this.closest('.k-grid').find('table.sn-survey-gridquestion-table');
                                            if (!isNaN(value))
                                                value = value.toString();
                                            if ($this.hasClass('rowTitle'))
                                                changeRowProperty(grid, rowIndex, "title", value);
                                            else if ($this.hasClass('columnTitle'))
                                                changeColumnTitle(grid, columnIndex, "title", value);
                                        }, 500);
                                    });

                                    var $addRowButton = $('.add-row');
                                    var $addColumnButton = $('.add-column');
                                    $addRowButton.on('click', function () {
                                        addNewRow($(this));
                                    });
                                    $addColumnButton.on('click', function () {
                                        if (!$(this).hasClass('disabled'))
                                            addNewColumn($(this));
                                    });

                                    if (data.columns.length === 10)
                                        $addColumnButton.addClass('disabled');

                                    $('.sn-icon-remove[data-removeable="row"]').on('click', function () {
                                        var index = $(this).closest('tr').index();
                                        removeRowByIndex(index, $grid);
                                    });
                                    $('.sn-icon-remove[data-removeable="column"]').on('click', function () {
                                        var index = $(this).closest('th').index();
                                        removeColumnByIndex(index, $grid);
                                    });

                                    var questionId = $(this.element).closest('.sn-survey-question').attr('id');
                                    var currentQuestion = survey.getQuestionByElement($('#' + questionId));

                                    survey.refreshPreview(questionId, SN.Fields.Grid.fill.template, currentQuestion, renderingFunction);
                                    //SN.Fields.Grid.fill.render(questionId, view, currentQuestion);
                                },
                                width: width,
                                height: height
                            });
                        }
                        function addNewRow($button) {
                            var id = $button.closest('.sn-survey-section').attr('id');
                            var section = survey.getSectionById(id);
                            var questionId = $button.closest('.sn-survey-question').attr('id');
                            var q = survey.getQuestionById(section, questionId);
                            var $grid = $button.closest('.k-grid').find('table.sn-survey-gridquestion-table');
                            var typeDropDown = $button.siblings().find("span#rowTypeChooser").data("kendoDropDownList");
                            var type = typeDropDown.value();
                            q.GridSchema.rows.push({
                                title: SN.Resources.SurveyList["UntitledRow"],
                                index: question.GridSchema.rows.length,
                                type: type
                            });
                            survey.saveDataToTextBox();
                            refreshGrid($grid);
                        }
                        function addNewColumn($button) {
                            var id = $button.closest('.sn-survey-section').attr('id');
                            var section = survey.getSectionById(id);
                            var questionId = $button.closest('.sn-survey-question').attr('id');
                            var q = survey.getQuestionById(section, questionId);
                            var $grid = $button.closest('.k-grid').find('table.sn-survey-gridquestion-table');
                            q.GridSchema.columns.push({
                                field: 'UntitledColumn' + question.GridSchema.columns.length,
                                title: SN.Resources.SurveyList["UntitledColumn"],
                                index: question.GridSchema.columns.length,
                                width: 150
                            });
                            survey.saveDataToTextBox();
                            refreshGrid($grid);

                            if (question.GridSchema.columns.length === 10) {
                                $grid.closest('.k-grid-lockedcolumns').find('.add-column').addClass('disabled');
                            }
                        }
                        function removeRowByIndex(index, $grid) {
                            if (question.GridSchema.rows.length > 1) {
                                question.GridSchema.rows.splice(index, 1);
                                for (var i = index; i < question.GridSchema.rows.length; i++) {
                                    question.GridSchema.rows[i].index -= 1;
                                }
                                survey.saveDataToTextBox();
                                refreshGrid($grid);
                            }
                        }
                        function removeColumnByIndex(index, $grid) {
                            question.GridSchema.columns.splice(index, 1);
                            for (var i = index; i < question.GridSchema.columns.length; i++) {
                                question.GridSchema.columns[i].index -= 1;
                            }
                            survey.saveDataToTextBox();
                            refreshGrid($grid);
                            if (question.GridSchema.columns.length < 10)
                                $grid.find('.add-column').removeClass('disabled');
                        }
                        function refreshGrid($grid) {
                            $grid.data("kendoGrid").destroy();
                            $grid.empty().unwrap();
                            $grid.siblings('.k-grid-header').remove();
                            $grid.unwrap();
                            createGrid();
                            survey.refreshPreview(questionId, template, question, renderingFunction);
                            $('.sn-survey-section-inner').find('input[type="text"]').on('focus', function () {
                                $(this).select();
                            });

                        }
                    }

                },
                SNFields: ['DisplayName', 'Description', 'Required'],
                Validation: {
                    Type: { type: "dropdown", index: 0, value: 'text' },
                    Rule: { type: "dropdown", cascadeFrom: 'Type', index: 1, value: 'grid-required' },
                    Value: { type: "string", index: 2 },
                    ErrorMessage: { type: "string", index: 3, value: SN.Resources.SurveyList["ErrorMessage-GridRequired"] }
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
                                    name: 'grid-required',
                                    text: SN.Resources.SurveyList["GridRequired"],
                                    value: true,
                                    type: 'boolean',
                                    method: function (e) {
                                        var $question = e.closest('.sn-question');
                                        var validate = $question.data('grid-required');
                                        var required = typeof $question.attr('custom-required') !== 'undefined';
                                        var $grid = $question.find('.sn-survey-gridquestion-grid');
                                        var type = $grid.find('input').attr('type');
                                        if (typeof validate !== 'undefined' && validate !== false) {
                                            var rowNumber = $grid.find('tr').length;
                                            var fNumber = 0;
                                            switch (type) {
                                                case 'radio':
                                                    for (var i = 0; i < $grid.find('tr').length; i++)
                                                        if ($grid.find('tr').eq(i).find('input[type="radio"]:checked').length > 0)
                                                            fNumber += 1;
                                                    break;
                                                case 'checkbox':
                                                    for (var i = 0; i < $grid.find('tr').length; i++)
                                                        if ($grid.find('tr').eq(i).find('input[type="checkbox"]:checked').length > 0)
                                                            fNumber += 1;
                                                    break;
                                                case 'text':
                                                    for (var i = 0; i < $grid.find('tr').length; i++) {
                                                        var cellNumber = $grid.find('tr').eq(i).find('td').length;
                                                        if ($grid.find('tr').eq(i).find('input[value=]').length < cellNumber)
                                                            fNumber += 1;
                                                    }
                                                    break;
                                                default:
                                                    for (var i = 0; i < $grid.find('tr').length; i++)
                                                        if ($grid.find('tr').eq(i).find('input[type="radio"]:checked').length > 0)
                                                            fNumber += 1;
                                                    break;
                                            }
                                            return (fNumber >= rowNumber);
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
        template: SN.Templates.SurveyList["gridEditor.html"],
        menu: [
            { field: 'Hint', text: SN.Resources.SurveyList["Hint-Menu"] }
        ]
    },
    fill: {
        template: SN.Templates.SurveyList["gridFill.html"],
        render: function (id, mode, question) {
            var q = question;
            if (typeof question.GridSchema === 'undefined')
                q = question.editor.schema.fields;

            var data = createDataFromGridSchema();
            var $grid = $('#' + id).find('.sn-survey-gridquestion-grid');
            var width = $grid.closest('.sn-survey-question-inner').width() - 20;


            var height = (q.GridSchema.rows.length + 1) * 30;
            var type = q.GridSchema.rows[0].type;
            if (q.GridSchema.columns.length > 4)
                height += 25;
            if ($grid.length > 0) {
                $grid.kendoGrid({
                    dataSource: {
                        data: data.dataSource,
                        schema: {
                            model: {
                                fields: data.fields
                            }
                        }
                    },
                    scrollable: true,
                    sortable: false,
                    filterable: false,
                    pageable: false,
                    resizable: false,
                    //reorderable: true,
                    columns: data.columns,
                    width: width,
                    dataBound: function (e) {
                        $grid.data("kendoGrid").resize();
                        var timeoutId;
                        $grid.find('input[type="checkbox"], input[type="radio"]').on('click', function () {
                            if ($(this).attr('type') === 'radio') {
                                var $tr = $(this).closest('tr');
                                $tr.find('input[type="radio"]').not(this).prop('checked', false);
                            }
                        });
                    }
                });
            }
            function createDataFromGridSchema() {
                var data = {};
                data.dataSource = [];
                data.fields = {};
                data.columns = [];
                for (var i = 0; i < q.GridSchema.rows.length; i++) {
                    var item = q.GridSchema.rows[i];
                    var row = {};
                    var template;
                    row.Title = item.title;
                    row.Index = item.index;
                    row.Type = item.type;

                    data.dataSource.push(row);
                }

                data.fields.Title = { type: "string" };
                data.columns.push({
                    field: "Title",
                    headerTemplate: '',
                    width: 250,
                    locked: true,
                    template: "<strong>#=Title#</strong>"
                });
                for (var j = 0; j < q.GridSchema.columns.length; j++) {
                    var column = q.GridSchema.columns[j];
                    if (item.type === 'text') {
                        row['field-' + column.index] = '';
                        data.fields['field-' + column.index] = { type: "string" }
                    }
                    else if (item.type === 'radio' && column.index === 0) {
                        row['field-' + column.index] = true;
                        data.fields['field-' + column.index] = { type: "string" };
                    }
                    else {
                        row['field-' + column.index] = false;
                        data.fields['field-' + column.index] = { type: "string" };
                    }

                    data.columns.push({
                        field: 'field-' + column.index,
                        title: column.title,
                        headerTemplate: '<strong>' + column.title + '</strong>',
                        template: function (e) {
                            return '<input type="' + e.Type + '" />'
                        },
                        lockable: false,
                        width: 150
                    });
                }
                return data;
            }
        },
        value: function ($question, questionId) {
            var survey = $('#surveyContainer').data('Survey');
            var id = $question.closest('.sn-survey-section').attr('id');
            var section = survey.getSectionById(id);
            var question = survey.getQuestionById(section, questionId);
            var saveableData = [];
            for (var i = 0; i < question.GridSchema.rows.length; i++) {
                var row = question.GridSchema.rows[i];
                saveableData[i] = { title: row.title, columns: [] };
                for (var j = 0; j < question.GridSchema.columns.length; j++) {
                    var column = question.GridSchema.columns[j];
                    if (row.type === 'text')
                        saveableData[i].columns[j] = { title: column.title, value: '' };
                    else
                        saveableData[i].columns[j] = { title: column.title, value: false };
                }
            }

            for (var y = 0; y < $('#' + questionId).find('.sn-survey-gridquestion-grid input').length; y++) {
                var $input = $($('#' + questionId).find('.sn-survey-gridquestion-grid input')[y]);
                var rowIndex = $input.closest('tr').index();
                var columnIndex = $input.closest('td').index();
                if ($input.attr('type') === 'radio' || $input.attr('type') === 'checkbox')
                    saveableData[rowIndex].columns[columnIndex].value = $input.prop('checked');
                else
                    saveableData[rowIndex].columns[columnIndex].value = $input.val();
            }

            return JSON.stringify(saveableData);
        }
    }
}