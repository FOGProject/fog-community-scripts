This is where a future cross-platform powershell module for controlling fog via the api
and other built-in tools will be found.
Sadly I won't have time to build it for a while.
However as I create snippets of functions I will add them to the snippets folder in .psm1 formats
If there are others that wish to help build on this, it would be appreciated, also very open to ideas.

Some things I'm planning on are

* a setup/config function for getting or manually setting the fog api token default values for all fog functions, as well as other universal things like fog server hostname, and an option of adding other stuff -COMPLETE
* some not directly fog related but helpful functions like creating start layouts from pre-structured legacy start menu, imagePrep function (utilizes sysprep), functions to install helpful windows tools for imaging like the Imaging Configuration designer for provisioning packages and the System Image Manager for creating sysprep unattend files. -StartMenu startscreen layout module done
* setup/config functions for getting and setting any fog configuration accessible via the api
* a install-FogService function - COMPLETE -put it in the fogapi module
* Deploying snapins on local or remote computers - COMPLETE using the fogapi module, examples not complete
* viewing local and remote fog logs, imaging history, snapin history, etc.
* Queuing all task types for local and remote computers
* basically everything that can be done via the api but just invoked with easy to learn ps commands like Start-ImageDeploy, Start-ImageCapture, Start-SnapinDeploy, etc. - Chose to do this different by utilzing autocomplete oh options and is essentialy complete. Wrapper functions could be easily created from existing module
* All of this with tab completion as well for the possible parameter options when known, such as the api object options host,group,task,etc. -COMPLETE
* The goal will to have it be with powershell 6 so these commands will be able to used on windows, mac, and linux -Untested but probably complete

