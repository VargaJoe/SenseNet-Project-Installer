<%@ Control Language="C#" AutoEventWireup="true" Inherits="SenseNet.Portal.UI.SingleContentView" %>

<sn:ContextInfo runat="server" Selector="CurrentContext" UsePortletContext="true" ID="myContext" />
<sn:ScriptRequest runat="server" ID="Scriptrequest1" Path="$skin/scripts/sn/SN.Survey.js" />
<sn:CssRequest runat="server" ID="surveyCss" Path="$skin/styles/SN.Survey.css" />

<div style="display: none">
    <sn:ShortText runat="server" ID="DisplayName" FieldName="DisplayName">
        <edittemplate>
            <asp:TextBox ID="InnerShortText" CssClass="sn-ctrl-displayname" runat="server"></asp:TextBox>
        </edittemplate>
    </sn:ShortText>
    <sn:LongText runat="server" ID="Description" FieldName="Description">
        <edittemplate>
            <asp:TextBox ID="InnerControl" runat="server" CssClass="sn-ctrl-description" TextMode="MultiLine"></asp:TextBox>
        </edittemplate>
    </sn:LongText>
    <sn:LongText runat="server" ID="RawJson" FieldName="RawJson">
        <edittemplate>
            <asp:TextBox ID="InnerControl" runat="server" CssClass="sn-ctrl-rawjson" TextMode="MultiLine"></asp:TextBox>
        </edittemplate>
    </sn:LongText>
    <sn:LongText runat="server" ID="IntroText" FieldName="IntroText">
        <edittemplate>
            <asp:TextBox ID="InnerControl" runat="server" CssClass="sn-ctrl-intro sn-ctrl-html" TextMode="MultiLine"></asp:TextBox>
        </edittemplate>
    </sn:LongText>
    <sn:LongText runat="server" ID="OutroText" FieldName="OutroText">
        <edittemplate>
            <asp:TextBox ID="InnerControl" runat="server" CssClass="sn-ctrl-outro sn-ctrl-html" TextMode="MultiLine"></asp:TextBox>
        </edittemplate>
    </sn:LongText>
</div>
<div id="surveyContainer" data-view="new"></div>
<div class="sn-panel sn-buttons">
    <span class="sn-button sn-submit ui-button ui-widget ui-state-default ui-corner-all" id="SaveButton" role="button" aria-disabled="false">Save</span>
    <span class="sn-button sn-submit sn-button-cancel ui-button ui-widget ui-state-default ui-corner-all" id="CancelButton" role="button" aria-disabled="false">Cancel</span>
</div>


<script>
    var currentListPath = '<%= myContext.Path %>';
    var survey = $('#surveyContainer').Survey({
        path: currentListPath,
        title: $('.sn-ctrl-displayname'),
        description: $('.sn-ctrl-description'),
        structure: $('.sn-ctrl-rawjson'),
        intro: $('.sn-ctrl-intro'),
        outro: $('.sn-ctrl-outro'),
        settings: [
            {
                name: 'GeneralSettings',
                items: [
                    { name: 'ValidFrom', type: 'datetime' },
                    { name: 'ValidTill', type: 'datetime' },
                    { name: 'EnableLifespan', type: 'boolean' }
                ]
            },
            {
                name: 'NotificationSettings',
                items: [
                    { name: 'EnableNotificationMail', type: 'boolean', value: false },
                    { name: 'EmailList', type: 'longtext', value: '' },
                    { name: 'EmailField', type: 'emailfield', value: '' },
                    { name: 'EmailFrom', type: 'shorttext', value: '' },
                    { name: 'MailSubject', type: 'shorttext', value: '' },
                    { name: 'AdminEmailTemplate', type: 'richtext', value: '' },
                    { name: 'SubmitterEmailTemplate', type: 'richtext', value: '' }
                ]
            }
        ]
    });
</script>
