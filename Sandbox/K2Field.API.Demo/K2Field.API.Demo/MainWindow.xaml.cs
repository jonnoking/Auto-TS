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

        public string GetMimeType(FileInfo fileInfo)
        {
            return GetMimeType(fileInfo.Extension.ToLower());
        }
    }
}
