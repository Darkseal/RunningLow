# RunningLow
Free PowerShell script to to check for low disk space and send e-mail alerts when it goes under a user-defined quota.

## Introduction
_RunningLow_ is a simple yet effective PowerShell script I coded a while ago to get to know when one of my servers is running low of disk space.

Whoever works with physical and/or virtualized Windows Servers is well aware of the importance of keeping this constantly under control: as soon as a server runs out of disk space it will be unable to fullfill a number of tasks, such as: create temporary files, store data on a database, performing system maintenance / backup / updates, create or update web sessions – assuming they are handled through I/O – and so on. Things can be even worse for those servers who host DBMS services such as MySQL and MS-SQL, as the sudden I/O unavailability could cause non-trivial damages to indexes, filesystem-based tables and data integrity.
 
The main purpose of _RunningLow_ is to prevent all that: it will check one or more local and/or network drives to see if their available free space went under a certain quota, and send a customizable alert to one or more e-mail addresses if that’s the case. I know, there are A LOT of admin suites and maintenance software that could be easily configured to the same thing: even Piriform’s CCleaner PRO does that! However, if you don’t have the money, the time or the amount of system resources required to install these apps, you might find out that this lightweight alternative could be worth a shot.

## Configuration

Here's a list of all RunningLow configuration settings (and their meaning). Each one of them corresponds to a command-line parameter, meaning that you can either set them using the CLI or change their default value within the script itself.

    - minSize
The minimum free disk space acceptable threshold: any checked drive with less available space will raise a warning.

    - hosts
If specified, will also check the disk space on the given colon-separated list of hostnames (machine names OR ip addresses) within the LAN. 

Example: $hosts = "HOSTNAME1:HOSTNAME2:129.168.0.115"

**IMPORTANT**: Connecting to remote machines will require launching *RunningLow* with elevated priviledges and having the ***Windows Management Service*** up, running and reachable (TCP port 5985) on the remote machine.

    - volumes
A colon-separated list of the drive volumes (letters) to check: set it to $null to check all local (non-network) drives.

Example: $volumes = "C:D";

    - email_to
If specified, will send a low-disk-space warning email to the given colon-separated addresses.

Example: $email_to = "my@email.com:your@email.com";

Default is $null (no e-mail will be sent). Replace it with your@email.com if you don't want to set it from the CLI.
	
    - email_username = "username@yourdomain.com"
    - email_password = "yourpassword"
    - email_smtp_host = "smtp.yourdomain.com"
    - email_smtp_port = 25
    - email_smtp_SSL = 0
    - email_from = "username@yourdomain.com"

The above parameters can be used to set up your SMTP configuration for sending the e-mail alerts: username, password & so on. It's strongly advisable to set them within the code instead of setting them from the CLI, as you might rarely want to change them. Needless to say, if you don't want RunningLow to send any e-mail, you might as well skip the whole part: just remember to set `-email_to` value to `$null` to have the code skip that as well.

## The Code

The first ten or so lines host the configuration settings, which you should change accordingly to your needs and depending to your specific scenario. The most important thing to understand is the first line: as we can see, we can either specify an array of drives – including network drives, as long as they’re permanently mapped to a local drive letter – or set a  _null_  value: if we go for the latter, the script will check all local drives.

The comments should be enough to guide you through this required part: however, if you need further assistance, you can use the comment section of this post to submit your query and I’ll do my best to help you with that.

## Testing

As soon as you’re done with the configuration, you can test the script from the standard Windows Command Prompt with the following command:

1

>  powershell -executionpolicy  bypass -File  RunningLow.ps1

… Or by typing  
.\RunningLow.ps1  from a PowerShell prompt.

As soon as you hit ENTER, you should see something like this:

[![RunningLow - A free PowerShell script to check for low disk space and send e-mail to System Administrators](https://i1.wp.com/www.ryadel.com/wp-content/uploads/2017/08/runninglow-powershell-script-disk-space-check.png?resize=710%2C299)](https://i1.wp.com/www.ryadel.com/wp-content/uploads/2017/08/runninglow-powershell-script-disk-space-check.png)

… Meaning that everything went ok.

### Sending E-Mail Alerts

Needless to say, you should then edit the script, raise the  **$minSize** value to a ridiculously high amount (such as 5TB) and run another test to ensure that the e-mail alerts will actually be sent:

[![RunningLow - A free PowerShell script to check for low disk space and send e-mail to System Administrators](https://i0.wp.com/www.ryadel.com/wp-content/uploads/2017/08/runninglow-powershell-script-disk-space-check-02.png?resize=710%2C274)](https://i0.wp.com/www.ryadel.com/wp-content/uploads/2017/08/runninglow-powershell-script-disk-space-check-02.png)

… That’s it.

## Installing

It goes without saying that the script should not be launched manually: the best thing we can do to ensure that it will be executed on regular basis is to create an appropriate entry in the Windows  **Task Scheduler**. In the example below,  **RunningLow**  will be executed once a day at noon:

[![RunningLow - A free PowerShell script to check for low disk space and send e-mail to System Administrators](https://i1.wp.com/www.ryadel.com/wp-content/uploads/2017/08/runninglow-task-scheduler-12-once-day-879x1024.png?resize=648%2C755)](https://i2.wp.com/www.ryadel.com/wp-content/uploads/2017/08/runninglow-task-scheduler-12-once-day.png)

In the  **New Action**  window you can either insert the full execution statement (including parameters) in the  **Program/script**  textbox, or use the  **Add arguments (optional)** textbox: the script will work either way. Similarly, you can specify the full path of the **RunningLow.ps1** file within the  **-File**  parameter or put it into the  **Start in (optional)**  textbox, just like we did in the above screenshot.

**IMPORTANT**: In the scheduled task  **General**  tab, be sure to activate the options **Run whether the user is logged on or not** and **Run with highest priviledges**, otherwise the script would run only if there’s a logged-in user during the execution time.

Be sure to test it again – by setting an insanely high  **$minSize** – on the server as well, to be sure that there are no firewalls or other restrictions that would block the e-mail alerts.

Well, that’s it for now: I sincerely hope that you will enjoy having **RunningLow** on your servers just like I do!

## References
 - [https://www.ryadel.com/en/runninglow-free-powershell-script-check-low-disk-space-send-email-alert/](https://www.ryadel.com/en/runninglow-free-powershell-script-check-low-disk-space-send-email-alert/) - Informative post about this project.
