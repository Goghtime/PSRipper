# Path to the JobIDs log file
$logFilePath = "D:\Ripper\logs\JobIDs.log"

# Read the log file
$logEntries = Get-Content -Path $logFilePath

# Extract the JobIDs and ProcessIDs
$jobIds = @()
$processIds = @()
foreach ($entry in $logEntries) {
    if ($entry -match "JobID: (\d+)") {
        $jobIds += [int]$matches[1]
    } elseif ($entry -match "ProcessID: (\d+)") {
        $processIds += [int]$matches[1]
    }
}

# Check active jobs
$activeJobs = @()
foreach ($jobId in $jobIds) {
    $job = Get-Job -Id $jobId -ErrorAction SilentlyContinue
    if ($job) {
        if ($job.State -eq "Running") {
            $activeJobs += [PSCustomObject]@{
                ID = $job.Id
                Type = "Job"
                State = $job.State
                StartTime = $job.PSBeginTime
            }
        }
    }
}

# Check active processes
$activeProcesses = @()
foreach ($processId in $processIds) {
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if ($process) {
        $activeProcesses += [PSCustomObject]@{
            ID = $process.Id
            Type = "Process"
            StartTime = $process.StartTime
        }
    }
}

# Output active jobs and processes
Write-Output "Active Jobs and Processes:"
$activeJobs + $activeProcesses | Format-Table -AutoSize
