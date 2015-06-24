<%-- _lcid="1033" _version="15.0.4420" _dal="1" --%>
<%-- _LocalBinding --%>
<%@ Page language="C#" MasterPageFile="~masterurl/default.master"    Inherits="Microsoft.SharePoint.WebPartPages.WebPartPage,Microsoft.SharePoint,Version=15.0.0.0,Culture=neutral,PublicKeyToken=71e9bce111e9429c" meta:webpartpageexpansion="full" meta:progid="SharePoint.WebPartPage.Document"  %>
<%@ Register Tagprefix="SharePoint" Namespace="Microsoft.SharePoint.WebControls" Assembly="Microsoft.SharePoint, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Register Tagprefix="Utilities" Namespace="Microsoft.SharePoint.Utilities" Assembly="Microsoft.SharePoint, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Import Namespace="Microsoft.SharePoint" %> <%@ Assembly Name="Microsoft.Web.CommandUI, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Register Tagprefix="WebPartPages" Namespace="Microsoft.SharePoint.WebPartPages" Assembly="Microsoft.SharePoint, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>
<asp:Content ContentPlaceHolderId="PlaceHolderPageTitle" runat="server">
	<SharePoint:ListItemProperty Property="BaseName" maxlength="40" runat="server"/>
</asp:Content>
<asp:Content ContentPlaceHolderId="PlaceHolderAdditionalPageHead" runat="server">
	<meta name="GENERATOR" content="Microsoft SharePoint" />
	<meta name="ProgId" content="SharePoint.WebPartPage.Document" />
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<meta name="CollaborationServer" content="SharePoint Team Web Site" />
	<SharePoint:ScriptBlock runat="server">
	var navBarHelpOverrideKey = "WSSEndUser";
	</SharePoint:ScriptBlock>
<SharePoint:StyleBlock runat="server">
body #s4-leftpanel {
	display:none;
}
.s4-ca {
	margin-left:0px;
}
</SharePoint:StyleBlock>
</asp:Content>
<asp:Content ContentPlaceHolderId="PlaceHolderSearchArea" runat="server">
	<SharePoint:DelegateControl runat="server"
		ControlId="SmallSearchInputBox"/>
</asp:Content>
<asp:Content ContentPlaceHolderId="PlaceHolderPageDescription" runat="server">
	<SharePoint:ProjectProperty Property="Description" runat="server"/>
</asp:Content>
<asp:Content ContentPlaceHolderId="PlaceHolderMain" runat="server">
	<div class="ms-hide">
	<WebPartPages:WebPartZone runat="server" title="loc:TitleBar" id="TitleBar" AllowLayoutChange="false" AllowPersonalization="false" Style="display:none;"><ZoneTemplate>
	<WebPartPages:TitleBarWebPart runat="server" HeaderTitle="jonno2" Title="Web Part Page Title Bar" FrameType="None" SuppressWebPartChrome="False" Description="" IsIncluded="True" ZoneID="TitleBar" PartOrder="2" FrameState="Normal" AllowRemove="False" AllowZoneChange="True" AllowMinimize="False" AllowConnect="True" AllowEdit="True" AllowHide="True" IsVisible="True" DetailLink="" HelpLink="" HelpMode="Modeless" Dir="Default" PartImageSmall="" MissingAssembly="Cannot import this Web Part." PartImageLarge="" IsIncludedFilter="" ExportControlledProperties="True" ConnectionID="00000000-0000-0000-0000-000000000000" ID="g_ff8c4233_9636_49ca_b784_33820122098c" AllowClose="False" ChromeType="None" ExportMode="All" __MarkupType="vsattributemarkup" __WebPartId="{FF8C4233-9636-49CA-B784-33820122098C}" WebPart="true" Height="" Width=""></WebPartPages:TitleBarWebPart>

	</ZoneTemplate></WebPartPages:WebPartZone>
  </div>
  <table class="ms-core-tableNoSpace ms-webpartPage-root" width="100%">
				<tr>
					<td id="_invisibleIfEmpty" name="_invisibleIfEmpty" colspan="3" valign="top" width="100%"> 
					<WebPartPages:WebPartZone runat="server" Title="loc:Header" ID="Header" FrameType="TitleBarOnly"><ZoneTemplate>
					<WebPartPages:ClientWebPart runat="server" FeatureId="b34691da-746e-444c-a80d-aabb5d152852" ProductId="b34691da-746e-444c-a80d-aabb5d152851" ProductWebId="eaff9988-cdce-4ef0-a213-7164da951d51" WebPartName="K2WorklistAppPart" Description="Displays the user&#39;s worklist." Title="K2 Worklist" ID="g_5698fa7b_0f7a_4717_a040_aec2335b056f" __MarkupType="vsattributemarkup" __WebPartId="{5698FA7B-0F7A-4717-A040-AEC2335B056F}" WebPart="true" __designer:IsClosed="false" partorder="2"></WebPartPages:ClientWebPart>

<WebPartPages:ClientWebPart runat="server" FeatureId="b34691da-746e-444c-a80d-aabb5d152852" ProductId="b34691da-746e-444c-a80d-aabb5d152851" ProductWebId="eaff9988-cdce-4ef0-a213-7164da951d51" WebPartName="K2FormViewerAppPart" Description="Displays a predefined K2 smartforms form." Title="K2 Form Viewer" ID="g_15abf60f_0a9c_4b08_b1dc_557dbf78ba50" __MarkupType="vsattributemarkup" __WebPartId="{15ABF60F-0A9C-4B08-B1DC-557DBF78BA50}" WebPart="true" __designer:IsClosed="false" partorder="4"></WebPartPages:ClientWebPart>

					</ZoneTemplate></WebPartPages:WebPartZone> </td>
				</tr>
				<tr>
					<td id="_invisibleIfEmpty" name="_invisibleIfEmpty" valign="top" height="100%"> 
					<WebPartPages:WebPartZone runat="server" Title="loc:LeftColumn" ID="LeftColumn" FrameType="TitleBarOnly"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone> </td>
					<td id="_invisibleIfEmpty" name="_invisibleIfEmpty" valign="top" height="100%"> 
					<WebPartPages:WebPartZone runat="server" Title="loc:MiddleColumn" ID="MiddleColumn" FrameType="TitleBarOnly"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone> </td>
					<td id="_invisibleIfEmpty" name="_invisibleIfEmpty" valign="top" height="100%"> 
					<WebPartPages:WebPartZone runat="server" Title="loc:RightColumn" ID="RightColumn" FrameType="TitleBarOnly"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone> </td>
				</tr>
				<tr>
					<td id="_invisibleIfEmpty" name="_invisibleIfEmpty" colspan="3" valign="top" width="100%"> 
					<WebPartPages:WebPartZone runat="server" Title="loc:Footer" ID="Footer" FrameType="TitleBarOnly"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone> </td>
				</tr>
				<SharePoint:ScriptBlock runat="server">if(typeof(MSOLayout_MakeInvisibleIfEmpty) == "function") {MSOLayout_MakeInvisibleIfEmpty();}</SharePoint:ScriptBlock>
		</table>
</asp:Content>
