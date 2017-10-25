# JIRATicketReferencesInBuild
This PowerShell script, produces a text file containing all the JIRA ticket reference numbers for the current sprint/release. It works well with the automated deployment/continous integration tool TeamCity.

The end result is that you can visit your UAT/QA website at http://www.yourwebsitehere.com/releaselog.txt and see a file similar to the sample one https://github.com/paulness/JIRATicketReferencesInBuild/blob/master/releaselog.txt.

Prerequisites

- You must be using GITHUB

- The first line of included commits must be of the form '([A-Za-z]+\-\d+)', other commits are ignored

  TICKET-REFNO
  Description

  e.g.
  NAVBAR-344
  Updated navbar

- Branches must be of the form, "the word release, hyphen, numerical release number" (release\-([0-9\.]+))$
  e.g.
  release-16.5

<b>Usage</b>

#Please change the following variables

$gitProjectFolder = "C:/GIT/SampleProject"

$releaseLogFilePath = "$gitProjectFolder\build\codedeploy\MyWebSite\releaselog.txt"

ProduceGitReleaseLog -gitProjectFolder $gitProjectFolder -releaseLogFilePath $releaseLogFilePath
