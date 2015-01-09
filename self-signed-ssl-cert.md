Importing a certificate on Mac OS X can be a bit of a hassle. Here's how it works for me.

* Click on the SSL lock in the URL bar. Then click "Certificate Information".
* Drag and drop the certificate to your desktop.
* Double click the certificate on your desktop, this will open a Mac OS X keychain dialog.
* Click "Add" to confirm you want to add it to your keychain.
* In the next dialog click "Always trust".
* It will ask you for your system password, enter it.

Now, normally this should be all you need to do. But for me this doesn't work, yet: When I reload the page in Chrome I'll still get the same SSL error. Instead of actually applying my choice to "Always trust" Mac OS X would only apply "Custom Settings" which don't seem to be sufficient.

This should fix it:

* In Mac OS X keychain search for your certificate, open it by double clicking on it.
* Under "Trust" change "Custom Settings" to "Always Trust" and close the window.
* It will ask you to authenticate again, do that.

After jumping through all of these hoops you should be able to access the site.
