This is just a simple read-me on the booking export.

 - Booking Export is sent in realtime as bookings are created or modified.
 - Booking Export can be sent in JSON / XML format.
 - The fields stay the same, only the format changes.
 - Please use the BookingXmlSample_Document.xml as a guide for documentation - it's available inline.
   - the documentation is very basic, assumes the user understands travel and the booking engine and can map the fields on their end.
   - if you need more information, best to check first with the "user/agent" of the booking engine and then if they need support, they can contact Odysseus Support for more details.

The sample documents and examples include "Booking" but the full payload is also attached as an example.
The full payload is actually what gets sent as the export. It has a parent element "Transaction" to help us manage future enhancements better.

 - the XML/JSON can change as we continue to evolve the product and add new API's and features.
 - you should ensure that you do not enforce the formats.
 - the format changes are typicall backward compatible and if we are deprecating a field, we will send out a notification.

July 20, 2021
- added booking mode + online/offline flag.

Mar 24, 2022
 - please note that the JSON/XML files are simply to provide you samples of the raw JSON/XML that will be sent. We won't actually export a file, we will post raw XML/JSON.



Response expected once you received the export:

JSON Response:
{"success":"true"} 
OR   
{"success":"false"}

XML Response:
<success>true</success>
OR
<success>false</success>


Aug 2022:
removed duplicate Phone node
added RefundableType:
<RefundableType>1</RefundableType>
0 = unknown, 1 = Refundable, 2 = Non Refundable Deposit, 3 = Non Refundable

June 2024: added new JSON samples for cruise, cruise+air, cruise+air+hotel

Apr 2025: Review new change log document added with details on new fields and also added new sample files.