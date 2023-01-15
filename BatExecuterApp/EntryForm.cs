using System.Diagnostics;

namespace BatExecuterApp
{
    public partial class EntryForm : Form
    {
        private string rootLocation = Application.StartupPath;
        private string batFileLocation = "\\uploadBCP\\";
        private string batName = "uploadBCP.bat";
        private string[] s = { "\\bin" };
        private string serverNameReplace = "actualservernamegoeshere";
        private string userNameReplace = "UserNameGoesHere";
        private string passwordNameReplace = "PasswordGoesHere";
        public EntryForm()
        {
            InitializeComponent();
        }

        private void btnExecute_Click(object sender, EventArgs e)
        {

            string serverName = txtServerName.Text;
            string userName = txtUserName.Text;
            string password = txtPassword.Text;
            if (!string.IsNullOrEmpty(userName) && !string.IsNullOrEmpty(password) && !string.IsNullOrEmpty(serverName))
            {
                ReplaceBatFile(serverName, userName, password);
                ExecuteCommand(batFileLocation = rootLocation.Split(s, StringSplitOptions.None)[0] + batFileLocation + batName);
            }
        }

        private void ReplaceBatFile(string serverName, string userName, string password)
        {
            
            batFileLocation = rootLocation.Split(s, StringSplitOptions.None)[0] + batFileLocation;
            if (File.Exists(batFileLocation + batName))

            {
                string str = File.ReadAllText(batFileLocation + batName);
                str = str.Replace(serverNameReplace, serverName);
                str = str.Replace(userNameReplace, userName);
                str = str.Replace(passwordNameReplace, password);
                File.WriteAllText(batFileLocation + batName, str);              

            }
        }
        public void ExecuteCommand(string file)
        {
            int exitCode;
            ProcessStartInfo processInfo;
            Process process;

            processInfo = new ProcessStartInfo(file);
            processInfo.CreateNoWindow = true;
            processInfo.UseShellExecute = false;
            // *** Redirect the output ***
            processInfo.RedirectStandardError = true;
            processInfo.RedirectStandardOutput = true;

            process = Process.Start(processInfo);
            process.WaitForExit();

            // *** Read the streams ***
            // Warning: This approach can lead to deadlocks, see Edit #2
            string output = process.StandardOutput.ReadToEnd();
            string error = process.StandardError.ReadToEnd();

            exitCode = process.ExitCode;

            MessageBox.Show((String.IsNullOrEmpty(output) ? "Execution Successfull" : output), (String.IsNullOrEmpty(error) ? "" : error)); 
            //Console.WriteLine("output>>" + (String.IsNullOrEmpty(output) ? "(none)" : output));
            //Console.WriteLine("error>>" + (String.IsNullOrEmpty(error) ? "(none)" : error));
            //Console.WriteLine("ExitCode: " + exitCode.ToString(), "ExecuteCommand");
            process.Close();
        }
    }
}