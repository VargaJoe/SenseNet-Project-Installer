<%@ Control Language="C#" AutoEventWireup="true" Inherits="SenseNet.Portal.Portlets.ContentCollectionView" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="SenseNet.Portal.Helpers" %>

<sn:ScriptRequest runat="server" ID="util" Path="$skin/scripts/sn/SN.Util.js" />
<sn:CssRequest CSSPath="$skin/styles/SN.Survey.css" ID="CssRequest1" runat="server" />

<div class="sn-contentlist sn-surveylist">

    <% if (Security.IsInRole("Editors"))
        { %>
    <sn:ActionLinkButton runat="server" CssClass="addSurveyList" ActionName="Add" NodePath="/Root/Sites/Default_Site/features/Surveys" ParameterString="ContentTypeName=/Root/ContentTemplates/SurveyList/SurveyList" IconVisible="False" Text="<%$ Resources:SurveyList,AddNewSurvey %>" />
    <% } %>

    <h2><%=GetGlobalResourceObject("SurveyList", "SavedSurveys")%>:</h2>
    <%foreach (var content in this.Model.Items)
        { %>
    <div class="sn-content sn-contentlist-item">
        <h1 class="sn-content-title" data-path='<%= content.Path %>' data-singleresponse='<%= content["OnlySingleResponse"] %>'>
            <a href="<%=Actions.ActionUrl(content, "Add", true, new { ContentTypeName = "SurveyListItem"})%>" target="_blank">
                <%= content.DisplayName %>
            </a>
            <a href="<%=Actions.ActionUrl(content, "Edit", true)%>" target="_blank">
                <img src="/Root/Global/images/icons/16/edit.png" />
            </a>
        </h1>
    </div>
    <%} %>
</div>

<script>
    $(function () {
        $('.sn-surveylist [data-singleresponse="True"]').each(function () {
            var $this = $(this);
            var path = $this.attr('data-path');
            var isFilled = odata.isFilled({ path: path });
            var numberOfChildren = odata.fetchContent({
                path: path,
                $select: ['DisplayName'],
                $filter: "isOf('SurveyListItem')",
                $top: 1,
                $skip: 1,
                $inlinecount: 'allpages',
                metadata: 'no'
            });
            $.when(isFilled).then(function (data) {
                if (data.isFilled){
                    $this.addClass('disabled');
                    $this.on('click', function () { return false; });
                }
            });
            $.when(numberOfChildren).then(function (data) {
                if (data.d.__count > 0)
                    $this.find('a').eq(1).remove();
            });
        });
    });
</script>
