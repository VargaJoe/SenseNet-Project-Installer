<%@ Control Language="C#" AutoEventWireup="true" Inherits="SenseNet.Portal.UI.SingleContentView" %>


<sn:scriptrequest runat="server" id="Scriptrequest1" path="$skin/scripts/sn/SN.Survey.js" />
<sn:cssrequest runat="server" id="surveyCss" path="$skin/styles/SN.Survey.css" />

<sn:ContextInfo runat="server" Selector="CurrentContext" UsePortletContext="true" ID="myContext" />

<div style="display: none">
    <sn:shorttext runat="server" id="DisplayName" fieldname="DisplayName">
        <EditTemplate>
            <asp:TextBox ID="InnerShortText" CssClass="sn-ctrl-displayname" runat="server"></asp:TextBox>
        </EditTemplate>
       </sn:shorttext>
    <sn:longtext runat="server" id="Description" fieldname="Description">
        <EditTemplate>
            <asp:TextBox ID="InnerControl" runat="server" CssClass="sn-ctrl-description" TextMode="MultiLine"></asp:TextBox>
        </EditTemplate>
    </sn:longtext>
    <sn:longtext runat="server" id="RawJson" fieldname="RawJson">
        <EditTemplate>
            <asp:TextBox ID="InnerControl" runat="server" CssClass="sn-ctrl-rawjson" TextMode="MultiLine"></asp:TextBox>
        </EditTemplate>
    </sn:longtext>
    <sn:longtext runat="server" id="IntroText" fieldname="IntroText">
        <EditTemplate>
            <asp:TextBox ID="InnerControl" runat="server" CssClass="sn-ctrl-intro sn-ctrl-html" TextMode="MultiLine"></asp:TextBox>
        </EditTemplate>
    </sn:longtext>
    <sn:longtext runat="server" id="OutroText" fieldname="OutroText">
        <EditTemplate>
            <asp:TextBox ID="InnerControl" runat="server" CssClass="sn-ctrl-outro sn-ctrl-html" TextMode="MultiLine"></asp:TextBox>
        </EditTemplate>
    </sn:longtext>
</div>
<div id="surveyContainer" data-view="edit"></div>
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
