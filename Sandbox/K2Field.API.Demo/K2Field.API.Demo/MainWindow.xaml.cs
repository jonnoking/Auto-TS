using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using SourceCode.SmartObjects.Client;
using System.Web;
using SourceCode.Forms.Management;
using SourceCode.Categories.Client;
using SourceCode.SmartObjects.Management;
using SourceCode.Workflow.Management;


namespace K2Field.API.Demo
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

//[List Method] 1. SharePoint_Integration_Workflow_Helper_Methods.LoadPackage(string siteUrl, string siteName, string listName string ListId, file packageFile) -> string Result (which will be the session name and required for all future methods)
//[List Method] 2. SharePoint_Integration_Workflow_Helper_Methods.RefactorSharepointArtifacts(string Result(session name), string siteUrl, string siteName, string listName string ListId) -> String Result
//[List Method] 3. SharePoint_Integration_Workflow_Helper_Methods.RefactorModel(string Result(session name), string siteUrl, string siteName, string listName string ListId) -> String Result
//[Scalar Method] [TAKES ALONG TIME] 4. SharePoint_Integration_Workflow_Helper_Methods.AutoResolve(string Result(session name), string siteUrl, string siteName, string listName string ListId) -> String Result
//[List Method] 5. SharePoint_Integration_Workflow_Helper_Methods.DeployPackage(string Result(session name)) -> String Result, String ConflictMessage(if there are any)
//[CAT: Package and Deployment - Progress - Get Progress] 6. Progress.GetProgress(string sessionName, “Deploy”) -> int NumberOfItemsProcessed, int TotalNumberOfItemsToProcess
//7. [Optional] File_Handler.DownloadDeploymentLog(string sessionName, “.log”) -> File DeploymentLog
 

        private void btnCallSmartObject_Click(object sender, RoutedEventArgs e)
        {
            SourceCode.Hosting.Client.BaseAPI.SCConnectionStringBuilder SCCS = new SourceCode.Hosting.Client.BaseAPI.SCConnectionStringBuilder();
            SCCS.Host = "localhost";
            SCCS.Port = 5555;
            SCCS.IsPrimaryLogin = true;
            SCCS.Integrated = true;

            SourceCode.SmartObjects.Client.SmartObjectClientServer Client = new SourceCode.SmartObjects.Client.SmartObjectClientServer();
            Client.CreateConnection();
            Client.Connection.Open(SCCS.ConnectionString);


            //byte[] fileBytes;
            //SmartFileProperty fileProperty = smartObject.Properties["MyFileProperty"] as SmartFileProperty;
            //fileProperty.FileName = "image.jpg";
            //fileProperty.Content = Convert.ToBase64String(bytes);

            using (Client.Connection)
            {
                string package = @"C:\K2\SharePoint Apps\K2 Application Accelerator - Leave Request v1.1.kspx";
                string SiteName = "Denallix-Bellevue";
                string SiteUrl = "https://portal.denallix.com/denallix-bellevue";
                string ListName = "Leave Approval";
                string ListId = "15afa672-15e1-4fc0-b410-84d7ef54285e";
                string SESSION = string.Empty;
               
                SourceCode.SmartObjects.Client.SmartObject Helper = Client.GetSmartObject("SharePoint_Integration_Workflow_Helper_Methods");
                Helper.ListMethods["LoadPackage"].InputProperties["SiteUrl"].Value = SiteUrl;
                Helper.ListMethods["LoadPackage"].InputProperties["SiteName"].Value = SiteName;
                Helper.ListMethods["LoadPackage"].InputProperties["ListName"].Value = ListName;
                Helper.ListMethods["LoadPackage"].InputProperties["ListId"].Value = ListId;
                ((SmartFileProperty)Helper.ListMethods["LoadPackage"].InputProperties["packageFile"]).FileName = System.IO.Path.GetFileName(package);
                ((SmartFileProperty)Helper.ListMethods["LoadPackage"].InputProperties["packageFile"]).Content = Base64File(package);
                
                Helper.MethodToExecute = "LoadPackage";

                SourceCode.SmartObjects.Client.SmartObjectCollection LoadPackageList = Client.ExecuteList(Helper).SmartObjectsList;
                SourceCode.SmartObjects.Client.SmartObject One = new SourceCode.SmartObjects.Client.SmartObject();
                
                foreach(SourceCode.SmartObjects.Client.SmartObject re in LoadPackageList)
                {
                    One = re;
                    break;
                }

                SESSION = One.Properties["k2_Int_Result"].Value;

                if (string.IsNullOrWhiteSpace(SESSION))
                {
                    MessageBox.Show("NO SESSION");
                }

                // REFACTOR

                Helper = null;
                Helper = Client.GetSmartObject("SharePoint_Integration_Workflow_Helper_Methods");
                Helper.ListMethods["RefactorSharePointArtifacts"].InputProperties["k2_Int_Result"].Value = SESSION;
                Helper.ListMethods["RefactorSharePointArtifacts"].InputProperties["SiteUrl"].Value = SiteUrl;
                Helper.ListMethods["RefactorSharePointArtifacts"].InputProperties["SiteName"].Value = SiteName;
                Helper.ListMethods["RefactorSharePointArtifacts"].InputProperties["ListName"].Value = ListName;
                Helper.ListMethods["RefactorSharePointArtifacts"].InputProperties["ListId"].Value = ListId;
                Helper.MethodToExecute = "RefactorSharePointArtifacts";

                LoadPackageList = Client.ExecuteList(Helper, 1, 1).SmartObjectsList; //Cast<SmartObject>().FirstOrDefault();
                One = new SourceCode.SmartObjects.Client.SmartObject();

                foreach (SourceCode.SmartObjects.Client.SmartObject re in LoadPackageList)
                {
                    One = re;
                    break;
                }

                SESSION = One.Properties["k2_Int_Result"].Value;

                if (string.IsNullOrWhiteSpace(SESSION))
                {
                    MessageBox.Show("NO SESSION");
                }

                // REFACTOR MODEL

                Helper = null;
                Helper = Client.GetSmartObject("SharePoint_Integration_Workflow_Helper_Methods");
                Helper.ListMethods["RefactorModel"].InputProperties["k2_Int_Result"].Value = SESSION;
                Helper.ListMethods["RefactorModel"].InputProperties["SiteUrl"].Value = SiteUrl;
                Helper.ListMethods["RefactorModel"].InputProperties["SiteName"].Value = SiteName;
                Helper.ListMethods["RefactorModel"].InputProperties["ListName"].Value = ListName;
                Helper.ListMethods["RefactorModel"].InputProperties["ListId"].Value = ListId;
                Helper.MethodToExecute = "RefactorModel";

                LoadPackageList = Client.ExecuteList(Helper).SmartObjectsList;
                One = new SourceCode.SmartObjects.Client.SmartObject();

                foreach (SourceCode.SmartObjects.Client.SmartObject re in LoadPackageList)
                {
                    One = re;
                    break;
                }

                SESSION = One.Properties["k2_Int_Result"].Value;

                if (string.IsNullOrWhiteSpace(SESSION))
                {
                    MessageBox.Show("NO SESSION");
                }

                // AUTO RESOLVE

                Helper = null;
                Helper = Client.GetSmartObject("SharePoint_Integration_Workflow_Helper_Methods");
                Helper.Methods["AutoResolve"].InputProperties["k2_Int_Result"].Value = SESSION;
                Helper.Methods["AutoResolve"].InputProperties["SiteUrl"].Value = SiteUrl;
                Helper.Methods["AutoResolve"].InputProperties["SiteName"].Value = SiteName;
                Helper.Methods["AutoResolve"].InputProperties["ListName"].Value = ListName;
                Helper.Methods["AutoResolve"].InputProperties["ListId"].Value = ListId;
                Helper.MethodToExecute = "AutoResolve";

                One = Client.ExecuteScalar(Helper);

                SESSION = One.Properties["k2_Int_Result"].Value;

                if (string.IsNullOrWhiteSpace(SESSION))
                {
                    MessageBox.Show("NO SESSION");
                }

                // DEPLOY PACKAGE

                Helper = null;
                Helper = Client.GetSmartObject("SharePoint_Integration_Workflow_Helper_Methods");
                Helper.ListMethods["DeployPackage"].InputProperties["k2_Int_Result"].Value = SESSION;
                Helper.MethodToExecute = "DeployPackage";

                LoadPackageList = Client.ExecuteList(Helper).SmartObjectsList;
                One = new SourceCode.SmartObjects.Client.SmartObject();

                foreach (SourceCode.SmartObjects.Client.SmartObject re in LoadPackageList)
                {
                    One = re;
                    break;
                }

                
                // CHECK STATUS


                // CLOSE SESSION - Package and Deployment - Session (SMO) - Close Method



            }

        }




        public string Base64File(string fileName)
        {
            using (var fileStream = System.IO.File.OpenRead(fileName))
            {
                byte[] buffer = new byte[fileStream.Length];
                fileStream.Read(buffer, 0, (int)fileStream.Length);
                return Convert.ToBase64String(buffer);
            }
        }

        public string GetMimeType(string extension)
        {
            string mimeType = "application/unknown";

            RegistryKey regKey = Registry.ClassesRoot.OpenSubKey(
                extension.ToLower()
                );

            if (regKey != null)
            {
                object contentType = regKey.GetValue("Content Type");

                if (contentType != null)
                    mimeType = contentType.ToString();
            }

            return mimeType;
        }

        public string GetMimeType(System.IO.FileInfo fileInfo)
        {
            return GetMimeType(fileInfo.Extension.ToLower());
        }

        private void btnDeleteSmartForms_Click(object sender, RoutedEventArgs e)
        {
            SourceCode.Hosting.Client.BaseAPI.SCConnectionStringBuilder SCCS = new SourceCode.Hosting.Client.BaseAPI.SCConnectionStringBuilder();
            SCCS.Host = "localhost";
            SCCS.Port = 5555;
            SCCS.IsPrimaryLogin = true;
            SCCS.Integrated = true;

            FormsManager formsmgr = new FormsManager();
            formsmgr.CreateConnection();
            formsmgr.Connection.Open(SCCS.ConnectionString);

            CategoryServer categorysvr = new CategoryServer();
            categorysvr.CreateConnection();
            categorysvr.Connection.Open(SCCS.ConnectionString);
            CategoryManager categorymgr = categorysvr.GetCategoryManager(1, true);

            Category Root = categorymgr.RootCategory;
            Category App = Root.CategoryManager.Categories.GetCategoryById(30365);
            //30332
            
            SmartObjectManagementServer soManager = new SmartObjectManagementServer();
            soManager.Connection = soManager.CreateConnection();
            soManager.Connection.Open(SCCS.ConnectionString);

            ContextCollection contexts = new ContextCollection();
            foreach(var item in App.DataList)
            {
                if (item.DataType.ToString().Equals("view", StringComparison.InvariantCultureIgnoreCase) || item.DataType.ToString().Equals("form", StringComparison.InvariantCultureIgnoreCase))
                {
                    Guid guid = new Guid(item.Data);

                    if (!contexts.Contains(guid))
                    {
                        contexts.Add(new Context(item.DataType.ToString().Equals("view", StringComparison.InvariantCultureIgnoreCase) ? ContextType.View : ContextType.Form, guid));
                    }
                }
            }
            if (contexts.Count > 0)
            {
                formsmgr.DeleteContexts(contexts);
            }

            foreach (var item in App.DataList)
            {
                if (item.DataType.ToString().Equals("smartobject", StringComparison.InvariantCultureIgnoreCase))
                {
                    Guid soid = new Guid(item.Data);
                    soManager.DeleteSmartObject(soid, true);
                }
            }

            var sos = from o in App.DataList where o.DataType.ToString().ToLower() == "thinclientprocess" select o.Data;

            var i = 0;

            // make smartobject call to SharePoint Integration Worfklow - get List - pass in SharePoint Settings Id
            // get first row


            WorkflowManagementServer WFS = new WorkflowManagementServer();
            WFS.CreateConnection();
            WFS.Connection.Open(SCCS.ConnectionString);

            SourceCode.Workflow.Management.Criteria.ProcessCriteriaFilter filter = new SourceCode.Workflow.Management.Criteria.ProcessCriteriaFilter();
            filter.AddRegularFilter(ProcessFields.ProcessFullName, SourceCode.Workflow.Management.Criteria.Comparison.Equals, @"Employee Leave Request\Leave Request");
            Processes z = WFS.GetProcesses(filter);

            //Process P = WFS.GetProcess(Convert.ToInt32(sos.First()));
            //string WFName = P.FullName;

            //var PSetId = P.ProcSetID;
            
            //ProcessSet PS = WFS.GetProcSet(PSetId);

            //WFS.DeleteProcessDefinition(WFName, 0, true);
            //Processes Pses = WFS.GetProcessVersions(z);
            foreach(Process pcs in z)
            {
                // exception - can't delete default version
                WFS.DeleteProcessDefinition(pcs.FullName, pcs.VersionNumber, true);
                
            }


            



        }
    }
}
