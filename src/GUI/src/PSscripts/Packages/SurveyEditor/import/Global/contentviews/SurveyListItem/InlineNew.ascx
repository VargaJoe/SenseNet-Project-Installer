<%@ Control Language="C#" AutoEventWireup="true" Inherits="SenseNet.Portal.UI.SingleContentView" %>
<%@ Import Namespace="SenseNet.Portal.Virtualization" %>

<sn:scriptrequest runat="server" id="Scriptrequest1" path="$skin/scripts/sn/SN.Survey.js" />
<sn:cssrequest runat="server" id="surveyCss" path="$skin/styles/SN.SurveyFill.css" />

<sn:ContextInfo runat="server" Selector="CurrentContext" UsePortletContext="true" ID="myContext" />
<div id="surveyContainer" data-view="browse"></div>
<script>
    var currentListPath = '<%= myContext.Path %>';
    var currentSurveyStructure = '<%= myContext.ContextNode["RawJson"] %>';
    var currentSurveyDisplayname = '<%= myContext.ContextNode["DisplayName"] %>';
    var currentSurveyDescription = '<%= myContext.ContextNode["Description"] %>';
    var currentSurveyIntro = '<%= myContext.ContextNode["IntroText"] %>';
    var currentSurveyOutro = '<%= myContext.ContextNode["OutroText"] %>';

    var survey = $('#surveyContainer').Survey({
        title: currentSurveyDisplayname,
        description: currentSurveyDescription,
        structure: currentSurveyStructure,
        intro: currentSurveyIntro,
        outro: currentSurveyOutro,
        path: currentListPath
        //errorTemplate: "<span>#=message#</span>"
    });

</script>
