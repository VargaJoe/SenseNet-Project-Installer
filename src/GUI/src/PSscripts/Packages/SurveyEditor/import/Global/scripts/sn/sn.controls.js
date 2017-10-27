// using $skin/scripts/jquery/jquery.js
// using $skin/scripts/sn/SN.js
// using $skin/scripts/sn/SN.Picker.js
// using $skin/scripts/kendoui/kendo.web.min.js
// using $skin/scripts/jquery/plugins/autoresize.jquery.min.js
// resource FieldControls

SN.Controls = {
    String: {
        render: function ($container, options) {
            var $input = $('<input type="text" class="sn-textbox k-input k-textbox shorttext" data-value="' + options.value + '"  id="textbox-' + options.key + '" name="' + options.key + '" />');
            if (typeof $container.attr('id') !== 'undefined') {
                var index = $container.attr('id').match(/\d+/);
                if (index !== null)
                    $input.attr('name', options.label + index);
            }
            if (options.required)
                $input.attr('required', '');
            if (typeof options.extraClass !== 'undefined' && options.extraClass)
                $input.addClass(options.extraClass);

            if (typeof options.value !== 'undefined' && options.value.length > 0)
                $input.val(options.value);

            $container.append(SN.Controls.FormRow.render(options.label, $input, options.info, '', options.key, options.placeholder));
            if (typeof options.info !== 'undefined' && options.info.length > 0)
                SN.Controls.Information.render(options.info, $input.parent());
            var timeoutId;
            $input.on('input', function () {
                var $this = $(this);
                clearTimeout(timeoutId);
                timeoutId = setTimeout(function () {
                    if (options.save && typeof options.save === 'function') {
                        if (typeof options.data !== 'undefined' && options.data instanceof jQuery)
                            options.save(options.data, SN.Controls.String.get($this), $this);
                        else if (typeof options.data !== 'undefined')
                            options.save(options.data, options.key, SN.Controls.String.get($this), $this);

                    }
                }, 500);
            });
        },
        get: function ($el) {
            return $el.val();
        },
        set: function ($el, value) {
            $el.val(value);
        }
    },
    DateTime: {
        render: function ($container, options) {
            var $input = $('<input class="sn-textbox k-input k-textbox datepicker"  data-value="' + options.value + '" id="textbox-' + options.key + '" name="' + options.key + '" />');
            if (typeof $container.attr('id') !== 'undefined') {
                var index = $container.attr('id').match(/\d+/);
                if (index !== null)
                    $input.attr('name', options.label + index);

            }
            if (options.required)
                $input.attr('required', '');
            if (typeof options.extraClass !== 'undefined' && options.extraClass)
                $input.addClass(options.extraClass);
            //$input.val(options.value);
            $container.append(SN.Controls.FormRow.render(options.label, $input, options.info, '', options.key, options.placeholder));
            $input.kendoDateTimePicker({

                change: function () {
                    if (options.save && typeof options.save === 'function') {
                        if (typeof options.data !== 'undefined' && options.data instanceof jQuery)
                            options.save(options.data, SN.Controls.String.get($input), $input);
                        else if (typeof options.data !== 'undefined')
                            options.save(options.data, options.key, SN.Controls.String.get($input), $input);

                    }
                }
            });
            $input.data('kendoDateTimePicker').value(new Date());
            if (typeof options.info !== 'undefined' && options.info.length > 0) {
                SN.Controls.Information.render(options.info, $input.closest('.sn-formrow'));
            }
        },
        get: function ($el) {
            return $el.val();
        },
        set: function ($el, value) {
            $el.val(value);
        }
    },
    Password: {
        render: function ($container, options) {
            var $input = $('<input type="password" class="sn-textbox k-input k-textbox"  id="textbox-' + options.key + '" name="' + options.key + '" />');
            if (typeof options.databind !== 'undefined')
                $input.attr({
                    'data-bind': options.databind
                })
            if (typeof $container.attr('id') !== 'undefined') {
                var index = $container.attr('id').match(/\d+/);
                $input.attr('name', options.label + index)
            }
            if (options.required)
                $input.attr('required', 'required');
            if (typeof options.extraClass !== 'undefined' && options.extraClass)
                $input.addClass(options.extraClass);
            if (typeof options.info !== 'undefined' && options.info.length > 0)
                SN.Controls.Information.render(options.info, $input.parent());
            $input.val(options.value);
            $container.append(SN.Controls.FormRow.render(options.label, $input, options.info, '', options.key, options.placeholder));
            $input.blur(function () {
                if (options.save && typeof options.save === 'function') {
                    if (typeof options.data !== 'undefined' && options.data instanceof jQuery)
                        options.save(options.data, SN.Controls.String.get($input));
                    else if (typeof options.data !== 'undefined')
                        options.save(options.data, options.key, SN.Controls.String.get($input));

                }
            });
        },
        get: function ($el) {
            return $el.val();
        },
        set: function ($el, value) {
            $el.val(value);
        }
    },
    Number: {
        render: function ($container, options) {
            var $input = $('<input type="number" class="sn-numeric-textbox k-input" id="numeric-textbox-' + options.key + '" name="' + options.key + '" />');

            if (typeof options.info !== 'undefined' && options.info.length > 0)
                SN.Controls.Information.render(options.info, $input.parent());
            if (options.required)
                $input.attr('required', '');
            if (typeof extraClass !== 'undefined' && options.extraClass)
                $input.addClass(options.extraClass);
            if (typeof options.info !== 'undefined' && options.info.length > 0)
                SN.Controls.Information.render(options.info, $input.parent());
            $input.val(options.value);
            $container.append(SN.Controls.FormRow.render(options.label, $input, options.info, '', options.key, options.placeholder));
            var timeoutId;
            $input.on('input', function () {
                var $this = $(this);
                clearTimeout(timeoutId);
                timeoutId = setTimeout(function () {
                    if (options.save && typeof options.save === 'function') {
                        options.save(options.data, options.key, SN.Controls.Number.get($input));
                    }
                }, 500);
            });
        },
        get: function ($el) {
            return $el.val();
        },
        set: function ($el, value) {
            $el.val(value);
        }
    },
    Boolean: {
        render: function ($container, options) {
            var $input = $('<input type="checkbox" class="sn-checkbox" id="chekbox-' + options.key + '" name="' + options.key + '" />');
            if (options.value)
                $input.prop('checked', true);
            $container.append(SN.Controls.FormRow.render(options.label, $input, options.info, '', options.key, options.placeholder));
            if (typeof options.info !== 'undefined' && options.info.length > 0)
                SN.Controls.Information.render(options.info, $input.parent());
            $input.on('change', function () {
                var $this = $(this);
                if (options.save && typeof options.save === 'function') {
                    options.save(options.data, options.key, SN.Controls.Boolean.get($input), $this);
                }
            });
        },
        get: function ($el) {
            return $el.is(':checked');
        },
        set: function ($el, value) {
            $el.prop('checked', value);
        }
    },
    Switch: {
        render: function ($container, options) {
            if (typeof options.id === 'undefined')
                options.id = options.key;
            var $input = $('<div class="onoffswitch" id="' + options.id + '"><input type="checkbox" class="sn-checkbox onoffswitch-checkbox" name="' + options.key + '" id="chekbox-' + options.id + '" /><label class="onoffswitch-label" for="chekbox-' + options.key + '"></label></div>');
            if (options.value)
                $input.find('input').prop('checked', true);
            $container.append(SN.Controls.FormRow.render(options.label, $input, options.info, '', options.key, options.placeholder));

            if (typeof options.info !== 'undefined' && options.info.length > 0)
                SN.Controls.Information.render(options.info, $input.parent());
            $('#' + options.id).on('click', function () {
                var $this = $(this);
                var $checkbox = $this.find('input');
                if ($checkbox.is(':checked'))
                    $checkbox.prop('checked', false);
                else
                    $checkbox.prop('checked', true);

                if (options.save && typeof options.save === 'function') {
                    options.save(options.data, options.key, SN.Controls.Switch.get($this), $this);
                }
                if (typeof options.click !== 'undefined')
                    options.click();
            });
        },
        get: function ($el) {
            return $el.find('input').is(':checked');
        },
        set: function ($el, value) {
            $el.find('input').prop('checked', value);
        }
    },
    Textarea: {
        render: function ($container, options) {
            var rows = options.rows || 1;
            var isRichText = false;
            if ((options.data instanceof jQuery && options.data.hasClass('sn-ctrl-html')) || options.isRichText)
                isRichText = true;

            var $input = $('<textarea rows="' + rows + '" class="sn-textarea k-textbox"  name="' + options.key + '" />');
            if (typeof options.extraAttr !== 'undefined') {
                $input.attr(options.extraAttr, '')


                $input.on('keyup input', function () {
                    var offset = this.offsetHeight - this.clientHeight;

                    $(this).css('height', 'auto').css('height', this.scrollHeight + offset);
                }).removeAttr('data-autoresize');

            }

            if (options.required)
                $input.attr('required', '');
            if (typeof options.extraClass !== 'undefined' && options.extraClass)
                $input.addClass(options.extraClass);
            $input.html(options.value);
            $container.append(SN.Controls.FormRow.render(options.label, $input, options.info, '', options.key, options.placeholder));
            var timeoutId;
            if (isRichText) {
                kendo.ui.editor.ColorTool.prototype.options.palette = "basic";
                $input.kendoEditor({
                    encoded: true,
                    //TODO: richText.config
                    tools: [
                    "bold",
                    "italic",
                    "underline",
                    "strikethrough",
                    "justifyLeft",
                    "justifyCenter",
                    "justifyRight",
                    "justifyFull",
                    "insertUnorderedList",
                    "insertOrderedList",
                    "indent",
                    "outdent",
                    "createLink",
                    "unlink",
                    "insertImage",
                    "insertFile",
                    "subscript",
                    "superscript",
                    "createTable",
                    "addRowAbove",
                    "addRowBelow",
                    "addColumnLeft",
                    "addColumnRight",
                    "deleteRow",
                    "deleteColumn",
                    "viewHtml",
                    "fontName",
                    "fontSize",
                    "foreColor",
                    "backColor"
                    ],
                    keyup: function (e) {
                        var $textbox = $(e.sender.element);
                        clearTimeout(timeoutId);
                        timeoutId = setTimeout(function () {
                            var $editor = $(e.sender.element).data("kendoEditor");
                            var value = $editor.value();
                            if (options.save && typeof options.save === 'function') {
                                if (typeof options.data !== 'undefined' && options.data instanceof jQuery)
                                    options.save(options.data, SN.Controls.String.get($this), $this);
                                else if (typeof options.data !== 'undefined')
                                    options.save(options.data, options.key, SN.Controls.String.get($this), $this);

                            }
                        }, 500);
                    },
                    change: function (e) {
                        var $textbox = $(e.sender.element);
                        clearTimeout(timeoutId);
                        timeoutId = setTimeout(function () {
                            var $editor = $(e.sender.element).data("kendoEditor");
                            var value = $editor.value();
                            if (options.save && typeof options.save === 'function') {
                                if (typeof options.data !== 'undefined' && options.data instanceof jQuery)
                                    options.save(options.data, SN.Controls.String.get($this), $this);
                                else if (typeof options.data !== 'undefined')
                                    options.save(options.data, options.key, SN.Controls.String.get($this), $this);

                            }
                        }, 500);
                    }
                });
            }
            $input.on('input', function () {
                var $this = $(this);
                clearTimeout(timeoutId);
                timeoutId = setTimeout(function () {
                    if (options.save && typeof options.save === 'function') {
                        if (typeof options.data !== 'undefined' && options.data instanceof jQuery)
                            options.save(options.data, SN.Controls.String.get($this), $this, options.key);
                        else if (typeof options.data !== 'undefined')
                            options.save(options.data, options.key, SN.Controls.String.get($this), $this);

                    }
                }, 500);
            });

            if (typeof options.info !== 'undefined' && options.info.length > 0)
                SN.Controls.Information.render(options.info, $input.closest('.sn-formrow'));
        }
    },
    Choice: {
        render: function ($container, options) {
            var $control;
            switch (options.type) {
                case 'dropdown':
                    $control = $('<select id="sn-dropdown-' + options.key + '"></select>');
                    break;
                case 'radiobuttonGroup':
                    $control = $('<div id="sn-radiobuttongroup-' + options.key + '"></div>');
                    break;
                case 'checkboxGroup':
                    $control = $('<div id="sn-checkboxgroup-' + options.key + '"></div>');
                    break;
                default:
                    $control = $('<select id="sn-dropdown-' + options.key + '"></select>');
            }
            if (options.required)
                $control.attr('required', '');
            if (typeof options.extraClass !== 'undefined' && options.extraClass)
                $control.addClass(options.extraClass);
            if (typeof options.info !== 'undefined' && options.info.length > 0)
                SN.Controls.Information.render(options.info, $control.parent());

        },
        get: function (id) { },
        set: function (id) { }
    },
    Paragraph: {
        render: function ($container, options) {
            var $el;
            if (typeof options.mode === 'undefined' || options.mode === 'browse') {
                $el = $('<p></p>').appendTo($container);
                $el.html(options.value);
                //var decodedHtml = $.parseHTML($el.text());
                //$el.html(decodedHtml);
            }
            else if (options.mode === 'edit') {
                if (typeof options.value === 'undefined')
                    options.value = '';
                SN.Controls.Textarea.render($container, {
                    label: options.label,
                    value: options.value,
                    extraClass: 'sn-textarea-paragraph',
                    extraAttr: options.extraAttr,
                    required: false,
                    id: options.key,
                    save: options.save,
                    data: options.data,
                    placeholder: options.placeholder,
                    isRichText: options.isRichText || false,
                    key: options.key
                });
            }
            if (typeof options.info !== 'undefined' && options.info.length > 0)
                SN.Controls.Information.render(options.info, $container);
        }
    },
    SingleReference: {
        render: function ($container, options) {
            var $referenceContainer = $('<div class="reference-container"></div>');
            var $input = $('<input type="text" class="sn-reference-textbox k-input k-textbox" placeHolder="' + options.label + '" id="textbox-' + options.key + '" name="' + options.key + '" />').appendTo($referenceContainer);
            var $button = $('<span class="browse-button">' + SN.Resources.SurveyList["Browse"] + '</span>').appendTo($referenceContainer);
            if (typeof $container.attr('id') !== 'undefined') {
                var index = $container.attr('id').match(/\d+/);
                if (index !== null)
                    $input.attr('name', options.label + index);
            }
            if (typeof options.extraClass !== 'undefined' && options.extraClass)
                $input.addClass(options.extraClass);

            $input.val(options.value);
            $container.append(SN.Controls.FormRow.render(options.label, $referenceContainer, options.info, '', options.key, options.placeholder));
            if (typeof options.info !== 'undefined' && options.info.length > 0)
                SN.Controls.Information.render(options.info, $input.parent());

            $button.on('click', function () {
                SN.PickerApplication.open({
                    MultiSelectMode: 'none', TreeRoots: options.treeRoot,
                    callBack: selectItem
                }); return false;
            });

            function selectItem(d) {
                $input.val(d[0].DisplayName).attr('title', d[0].Path);

                if (options.save && typeof options.save === 'function') {
                    options.save($input, options.key, SN.Controls.SingleReference.get($input), $input);
                }
            }
        },
        get: function ($el) {
            return $el.attr('title');
        },
        set: function ($el, value) {
            $el.attr('title', value);
        }
    },
    List: {
        render: function (id) {
            return $('<div class="sn-inner-form ' + id + '"></div>');
        }
    },
    ListItem: {},
    Grid: {
        render: function ($container, options) {

            var $grid = $('<div class="sn-grid" id="' + options.gridId + '"></div>');
            $grid.kendoGrid({
                dataSource: {
                    data: options.dataSource,
                    schema: {
                        model: {
                            id: options.id,
                            fields: options.fields
                        }
                    },
                    pageSize: 20
                },
                scrollable: false,
                sortable: true,
                pageable: {
                    input: false,
                    numeric: false
                },
                columns: options.columns || null,
                toolbar: options.toolbar || null,
                editable: {
                    mode: "popup",
                    window: {
                        animation: false,
                        width: "600px",
                    }
                },
                save: options.save,
                remove: options.remove,
                dataBound: function () {
                    if (this.dataSource.totalPages() == 1 || this.dataSource.total() === 0) {
                        this.pager.element.hide();
                    }
                }
            });

            $container.append($grid);
        }
    },
    GridRow: {
        remove: function () {

        },
        add: function () {

        },
        edit: function () {

        }
    },
    Form: {
        render: function ($container) {
            return $('<div class="sn-editor-form"></div>');
        }
    },
    FormRow: {
        render: function (label, $input, info, error, key, placeholder) {
            var $row = $('<div class="sn-formrow"></div>');
            if (typeof label !== 'undefined' && label.length > 0)
                var $label = $('<label for="chekbox-' + key + '">' + label + ':</label>').appendTo($row);

            if (typeof placeholder !== 'undefined' && placeholder.length > 0)
                $input.attr('placeholder', placeholder)

            $input.appendTo($row);

            if (typeof error !== 'undefined' && error.length > 0)
                var $error = $('<span class="sn-icon sn-icon-error"></span>').appendTo($row);
            if (typeof info !== 'undefined' && info.length > 0)
                var $info = $('<span class="sn-icon sn-icon-info"></span>').appendTo($row);

            return $row;
        }
    },
    FieldGroup: {
        render: function ($container, id) {
            $container.append('<div id="' + id + '" class="sn-fieldgroup"></div>');
        }
    },
    H1: {
        render: function ($container, options) {
            if (typeof options.mode === 'undefined' || options.mode === 'browse') {
                var $el = $('<h1>' + options.label + '</h1>').appendTo($container);
            }
            else if (options.mode === 'edit') {
                if (typeof options.value === 'undefined')
                    options.value = '';
                SN.Controls.String.render($container, {
                    label: options.label,
                    value: options.value,
                    extraClass: 'sn-textbox-h1',
                    required: true,
                    save: options.save,
                    data: options.data,
                    key: options.key
                });
            }
            if (typeof options.info !== 'undefined' && options.info.length > 0)
                SN.Controls.Information.render(options.info, $el);
        }
    },
    H2: {
        render: function ($container, options) {
            var $el = $('<h2>' + options.title + '</h2>').appendTo($container);
            if (typeof options.info !== 'undefined')
                SN.Controls.Information.render(options.info, $el);
            if (typeof options.hint !== 'undefined')
                SN.Controls.Information.render(options.hint, $el);
        }
    },
    H3: {
        render: function ($container, options) {
            var $el = $('<h3>' + options.label + '</h3>').appendTo($container);
            if (typeof options.info !== 'undefined')
                SN.Controls.Information.render(options.info, $el);
        }
    },
    H4: {
        render: function ($container, options) {
            var $el = $('<h4>' + options.label + '</h4>').appendTo($container);
            if (typeof options.info !== 'undefined')
                SN.Controls.Information.render(options.info, $el);
        }
    },
    H5: {
        render: function ($container, options) {
            var $el = $('<h5>' + options.label + '</h5>').appendTo($container);
            if (typeof options.info !== 'undefined')
                SN.Controls.Information.render(options.info, $el);
        }
    },
    H6: {
        render: function ($container, options) {
            var $el = $('<h6>' + options.title + '</h6>').appendTo($container);
            if (typeof options.info !== 'undefined')
                SN.Controls.Information.render(options.info, $el);
        }
    },
    Information: {
        render: function (info, $el) {
            if (info.length > 0) {
                var $info = $('<span class="sn-field-info"><span class="sn-icon sn-icon-info fa fa-info-circle"></span></span>').appendTo($el);
                $info.kendoTooltip({
                    content: info,
                    showOn: "click",
                    position: "right",
                    width: 200
                });
            }
        }
    },
    Relationship: {
        Xor: function ($group) {
            $group.find('input[value=]').closest('.sn-formrow').addClass('disabled');
            $group.find('.sn-formrow').on('click', function () {
                var $this = $(this);
                $this.find('input').focus();
                if ($this.closest('.sn-formrow').hasClass('disabled')) {
                    $group.find('input').closest('.sn-formrow').addClass('disabled');
                    $this.closest('.sn-formrow').removeClass('disabled');
                }
            });

            var timeoutId;
            $group.find('input').on('input', function () {
                var $this = $(this);
                clearTimeout(timeoutId);
                timeoutId = setTimeout(function () {
                    $this.closest('div').siblings('div').find('input').val('');
                }, 500);
            });
        }
    }
}
