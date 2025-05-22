Chat App API
Chat applications support session persistence, allowing previous chat history to be used as context for responses. This can be applicable for chatbot, customer service AI, etc.

Base URL
Code
https://trendgpt-difytest.testenvs.click/v1

Copy
Copied!
Authentication
The Service API uses API-Key authentication. Strongly recommend storing your API Key on the server-side, not shared or stored on the client-side, to avoid possible API-Key leakage that can lead to serious consequences.

For all API requests, include your API Key in the AuthorizationHTTP Header, as shown below:

Code
  Authorization: Bearer {API_KEY}


Copy
Copied!
POST
/chat-messages
Send Chat Message
Send a request to the chat application.

Request Body
Name
query
Type
string
Description
User Input/Question content

Name
inputs
Type
object
Description
Allows the entry of various variable values defined by the App. The inputs parameter contains multiple key/value pairs, with each key corresponding to a specific variable and each value being the specific value for that variable. Default {}

Name
response_mode
Type
string
Description
The mode of response return, supporting:

streaming Streaming mode (recommended), implements a typewriter-like output through SSE (Server-Sent Events).
blocking Blocking mode, returns result after execution is complete. (Requests may be interrupted if the process is long) Due to Cloudflare restrictions, the request will be interrupted without a return after 100 seconds. Note: blocking mode is not supported in Agent Assistant mode
Name
user
Type
string
Description
User identifier, used to define the identity of the end-user for retrieval and statistics. Should be uniquely defined by the developer within the application.

Name
conversation_id
Type
string
Description
Conversation ID, to continue the conversation based on previous chat records, it is necessary to pass the previous message's conversation_id.

Name
files
Type
array[object]
Description
File list, suitable for inputting files (images) combined with text understanding and answering questions, available only when the model supports Vision capability.

type (string) Supported type: image (currently only supports image type)
transfer_method (string) Transfer method, remote_url for image URL / local_file for file upload
url (string) Image URL (when the transfer method is remote_url)
upload_file_id (string) Uploaded file ID, which must be obtained by uploading through the File Upload API in advance (when the transfer method is local_file)
Name
auto_generate_name
Type
bool
Description
Auto-generate title, default is true. If set to false, can achieve async title generation by calling the conversation rename API and setting auto_generate to true.

Response
When response_mode is blocking, return a CompletionResponse object. When response_mode is streaming, return a ChunkCompletionResponse stream.

ChatCompletionResponse
Returns the complete App result, Content-Type is application/json.

event (string) 事件类型，固定为 message
task_id (string) 任务 ID，用于请求跟踪和下方的停止响应接口
id (string) 唯一ID
message_id (string) Unique message ID
conversation_id (string) Conversation ID
mode (string) App mode, fixed as chat
answer (string) Complete response content
metadata (object) Metadata
usage (Usage) Model usage information
retriever_resources (array[RetrieverResource]) Citation and Attribution List
created_at (int) Message creation timestamp, e.g., 1705395332
ChunkChatCompletionResponse
Returns the stream chunks outputted by the App, Content-Type is text/event-stream. Each streaming chunk starts with data:, separated by two newline characters \n\n, as shown below:

data: {"event": "message", "task_id": "900bbd43-dc0b-4383-a372-aa6e6c414227", "id": "663c5084-a254-4040-8ad3-51f2a3c1a77c", "answer": "Hi", "created_at": 1705398420}\n\n

Copy
Copied!
The structure of the streaming chunks varies depending on the event:

event: message LLM returns text chunk event, i.e., the complete text is output in a chunked fashion.
task_id (string) Task ID, used for request tracking and the below Stop Generate API
message_id (string) Unique message ID
conversation_id (string) Conversation ID
answer (string) LLM returned text chunk content
created_at (int) Creation timestamp, e.g., 1705395332
event: agent_message LLM returns text chunk event, i.e., with Agent Assistant enabled, the complete text is output in a chunked fashion (Only supported in Agent mode)
task_id (string) Task ID, used for request tracking and the below Stop Generate API
message_id (string) Unique message ID
conversation_id (string) Conversation ID
answer (string) LLM returned text chunk content
created_at (int) Creation timestamp, e.g., 1705395332
event: tts_message TTS audio stream event, that is, speech synthesis output. The content is an audio block in Mp3 format, encoded as a base64 string. When playing, simply decode the base64 and feed it into the player. (This message is available only when auto-play is enabled)
task_id (string) Task ID, used for request tracking and the stop response interface below
message_id (string) Unique message ID
audio (string) The audio after speech synthesis, encoded in base64 text content, when playing, simply decode the base64 and feed it into the player
created_at (int) Creation timestamp, e.g.: 1705395332
event: tts_message_end TTS audio stream end event, receiving this event indicates the end of the audio stream.
task_id (string) Task ID, used for request tracking and the stop response interface below
message_id (string) Unique message ID
audio (string) The end event has no audio, so this is an empty string
created_at (int) Creation timestamp, e.g.: 1705395332
event: agent_thought thought of Agent, contains the thought of LLM, input and output of tool calls (Only supported in Agent mode)
id (string) Agent thought ID, every iteration has a unique agent thought ID
task_id (string) Task ID, used for request tracking and the below Stop Generate API
message_id (string) Unique message ID
position (int) Position of current agent thought, each message may have multiple thoughts in order.
thought (string) What LLM is thinking about
observation (string) Response from tool calls
tool (string) A list of tools represents which tools are called，split by ;
tool_input (string) Input of tools in JSON format. Like: {"dalle3": {"prompt": "a cute cat"}}.
created_at (int) Creation timestamp, e.g., 1705395332
message_files (array[string]) Refer to message_file event
file_id (string) File ID
conversation_id (string) Conversation ID
event: message_file Message file event, a new file has created by tool
id (string) File unique ID
type (string) File type，only allow "image" currently
belongs_to (string) Belongs to, it will only be an 'assistant' here
url (string) Remote url of file
conversation_id (string) Conversation ID
event: message_end Message end event, receiving this event means streaming has ended.
task_id (string) Task ID, used for request tracking and the below Stop Generate API
message_id (string) Unique message ID
conversation_id (string) Conversation ID
metadata (object) Metadata
usage (Usage) Model usage information
retriever_resources (array[RetrieverResource]) Citation and Attribution List
event: message_replace Message content replacement event. When output content moderation is enabled, if the content is flagged, then the message content will be replaced with a preset reply through this event.
task_id (string) Task ID, used for request tracking and the below Stop Generate API
message_id (string) Unique message ID
conversation_id (string) Conversation ID
answer (string) Replacement content (directly replaces all LLM reply text)
created_at (int) Creation timestamp, e.g., 1705395332
event: error Exceptions that occur during the streaming process will be output in the form of stream events, and reception of an error event will end the stream.
task_id (string) Task ID, used for request tracking and the below Stop Generate API
message_id (string) Unique message ID
status (int) HTTP status code
code (string) Error code
message (string) Error message
event: ping Ping event every 10 seconds to keep the connection alive.
Errors
404, Conversation does not exists
400, invalid_param, abnormal parameter input
400, app_unavailable, App configuration unavailable
400, provider_not_initialize, no available model credential configuration
400, provider_quota_exceeded, model invocation quota insufficient
400, model_currently_not_support, current model unavailable
400, completion_request_error, text generation failed
500, internal server error
Request
POST
/chat-messages
curl -X POST 'https://trendgpt-difytest.testenvs.click/v1/chat-messages' \
--header 'Authorization: Bearer {api_key}' \
--header 'Content-Type: application/json' \
--data-raw '{
    "inputs": {},
    "query": "What are the specs of the iPhone 13 Pro Max?",
    "response_mode": "streaming",
    "conversation_id": "",
    "user": "abc-123",
    "files": [
      {
        "type": "image",
        "transfer_method": "remote_url",
        "url": "https://cloud.dify.ai/logo/logo-site.png"
      }
    ]
}'

Copy
Copied!
Blocking Mode
Response
{
    "event": "message",
    "task_id": "c3800678-a077-43df-a102-53f23ed20b88", 
    "id": "9da23599-e713-473b-982c-4328d4f5c78a",
    "message_id": "9da23599-e713-473b-982c-4328d4f5c78a",
    "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2",
    "mode": "chat",
    "answer": "iPhone 13 Pro Max specs are listed here:...",
    "metadata": {
        "usage": {
            "prompt_tokens": 1033,
            "prompt_unit_price": "0.001",
            "prompt_price_unit": "0.001",
            "prompt_price": "0.0010330",
            "completion_tokens": 128,
            "completion_unit_price": "0.002",
            "completion_price_unit": "0.001",
            "completion_price": "0.0002560",
            "total_tokens": 1161,
            "total_price": "0.0012890",
            "currency": "USD",
            "latency": 0.7682376249867957
        },
        "retriever_resources": [
            {
                "position": 1,
                "dataset_id": "101b4c97-fc2e-463c-90b1-5261a4cdcafb",
                "dataset_name": "iPhone",
                "document_id": "8dd1ad74-0b5f-4175-b735-7d98bbbb4e00",
                "document_name": "iPhone List",
                "segment_id": "ed599c7f-2766-4294-9d1d-e5235a61270a",
                "score": 0.98457545,
                "content": "\"Model\",\"Release Date\",\"Display Size\",\"Resolution\",\"Processor\",\"RAM\",\"Storage\",\"Camera\",\"Battery\",\"Operating System\"\n\"iPhone 13 Pro Max\",\"September 24, 2021\",\"6.7 inch\",\"1284 x 2778\",\"Hexa-core (2x3.23 GHz Avalanche + 4x1.82 GHz Blizzard)\",\"6 GB\",\"128, 256, 512 GB, 1TB\",\"12 MP\",\"4352 mAh\",\"iOS 15\""
            }
        ]
    },
    "created_at": 1705407629
}

Copy
Copied!
Streaming Mode ( Basic Assistant )
Response
  data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " I", "created_at": 1679586595}
  data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": "'m", "created_at": 1679586595}
  data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " glad", "created_at": 1679586595}
  data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " to", "created_at": 1679586595}
  data: {"event": "message", "message_id" : "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " meet", "created_at": 1679586595}
  data: {"event": "message", "message_id" : "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " you", "created_at": 1679586595}
  data: {"event": "message_end", "id": "5e52ce04-874b-4d27-9045-b3bc80def685", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "metadata": {"usage": {"prompt_tokens": 1033, "prompt_unit_price": "0.001", "prompt_price_unit": "0.001", "prompt_price": "0.0010330", "completion_tokens": 135, "completion_unit_price": "0.002", "completion_price_unit": "0.001", "completion_price": "0.0002700", "total_tokens": 1168, "total_price": "0.0013030", "currency": "USD", "latency": 1.381760165997548}, "retriever_resources": [{"position": 1, "dataset_id": "101b4c97-fc2e-463c-90b1-5261a4cdcafb", "dataset_name": "iPhone", "document_id": "8dd1ad74-0b5f-4175-b735-7d98bbbb4e00", "document_name": "iPhone List", "segment_id": "ed599c7f-2766-4294-9d1d-e5235a61270a", "score": 0.98457545, "content": "\"Model\",\"Release Date\",\"Display Size\",\"Resolution\",\"Processor\",\"RAM\",\"Storage\",\"Camera\",\"Battery\",\"Operating System\"\n\"iPhone 13 Pro Max\",\"September 24, 2021\",\"6.7 inch\",\"1284 x 2778\",\"Hexa-core (2x3.23 GHz Avalanche + 4x1.82 GHz Blizzard)\",\"6 GB\",\"128, 256, 512 GB, 1TB\",\"12 MP\",\"4352 mAh\",\"iOS 15\""}]}}
  data: {"event": "tts_message", "conversation_id": "23dd85f3-1a41-4ea0-b7a9-062734ccfaf9", "message_id": "a8bdc41c-13b2-4c18-bfd9-054b9803038c", "created_at": 1721205487, "task_id": "3bf8a0bb-e73b-4690-9e66-4e429bad8ee7", "audio": "qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq"}
  data: {"event": "tts_message_end", "conversation_id": "23dd85f3-1a41-4ea0-b7a9-062734ccfaf9", "message_id": "a8bdc41c-13b2-4c18-bfd9-054b9803038c", "created_at": 1721205487, "task_id": "3bf8a0bb-e73b-4690-9e66-4e429bad8ee7", "audio": ""}

Copy
Copied!
Response Example(Agent Assistant)
Response
data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " I", "created_at": 1679586595}
data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": "'m", "created_at": 1679586595}
data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " glad", "created_at": 1679586595}
data: {"event": "message", "message_id": "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " to", "created_at": 1679586595}
data: {"event": "message", "message_id" : "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " meet", "created_at": 1679586595}
data: {"event": "message", "message_id" : "5ad4cb98-f0c7-4085-b384-88c403be6290", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "answer": " you", "created_at": 1679586595}
data: {"event": "message_end", "id": "5e52ce04-874b-4d27-9045-b3bc80def685", "conversation_id": "45701982-8118-4bc5-8e9b-64562b4555f2", "metadata": {"usage": {"prompt_tokens": 1033, "prompt_unit_price": "0.001", "prompt_price_unit": "0.001", "prompt_price": "0.0010330", "completion_tokens": 135, "completion_unit_price": "0.002", "completion_price_unit": "0.001", "completion_price": "0.0002700", "total_tokens": 1168, "total_price": "0.0013030", "currency": "USD", "latency": 1.381760165997548}, "retriever_resources": [{"position": 1, "dataset_id": "101b4c97-fc2e-463c-90b1-5261a4cdcafb", "dataset_name": "iPhone", "document_id": "8dd1ad74-0b5f-4175-b735-7d98bbbb4e00", "document_name": "iPhone List", "segment_id": "ed599c7f-2766-4294-9d1d-e5235a61270a", "score": 0.98457545, "content": "\"Model\",\"Release Date\",\"Display Size\",\"Resolution\",\"Processor\",\"RAM\",\"Storage\",\"Camera\",\"Battery\",\"Operating System\"\n\"iPhone 13 Pro Max\",\"September 24, 2021\",\"6.7 inch\",\"1284 x 2778\",\"Hexa-core (2x3.23 GHz Avalanche + 4x1.82 GHz Blizzard)\",\"6 GB\",\"128, 256, 512 GB, 1TB\",\"12 MP\",\"4352 mAh\",\"iOS 15\""}]}}
data: {"event": "tts_message", "conversation_id": "23dd85f3-1a41-4ea0-b7a9-062734ccfaf9", "message_id": "a8bdc41c-13b2-4c18-bfd9-054b9803038c", "created_at": 1721205487, "task_id": "3bf8a0bb-e73b-4690-9e66-4e429bad8ee7", "audio": "qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq"}
data: {"event": "tts_message_end", "conversation_id": "23dd85f3-1a41-4ea0-b7a9-062734ccfaf9", "message_id": "a8bdc41c-13b2-4c18-bfd9-054b9803038c", "created_at": 1721205487, "task_id": "3bf8a0bb-e73b-4690-9e66-4e429bad8ee7", "audio": ""}

Copy
Copied!
POST
/files/upload
File Upload
Upload a file (currently only images are supported) for use when sending messages, enabling multimodal understanding of images and text. Supports png, jpg, jpeg, webp, gif formats. Uploaded files are for use by the current end-user only.

Request Body
This interface requires a multipart/form-data request.

file (File) Required The file to be uploaded.
user (string) Required User identifier, defined by the developer's rules, must be unique within the application.
Response
After a successful upload, the server will return the file's ID and related information.

id (uuid) ID
name (string) File name
size (int) File size (bytes)
extension (string) File extension
mime_type (string) File mime-type
created_by (uuid) End-user ID
created_at (timestamp) Creation timestamp, e.g., 1705395332
Errors
400, no_file_uploaded, a file must be provided
400, too_many_files, currently only one file is accepted
400, unsupported_preview, the file does not support preview
400, unsupported_estimate, the file does not support estimation
413, file_too_large, the file is too large
415, unsupported_file_type, unsupported extension, currently only document files are accepted
503, s3_connection_failed, unable to connect to S3 service
503, s3_permission_denied, no permission to upload files to S3
503, s3_file_too_large, file exceeds S3 size limit
500, internal server error
Request Example
Request
POST
/files/upload
curl -X POST 'https://trendgpt-difytest.testenvs.click/v1/files/upload' \
--header 'Authorization: Bearer {api_key}' \
--form 'file=@localfile;type=image/[png|jpeg|jpg|webp|gif] \
--form 'user=abc-123'

Copy
Copied!
Response Example
Response
{
  "id": "72fa9618-8f89-4a37-9b33-7e1178a24a67",
  "name": "example.png",
  "size": 1024,
  "extension": "png",
  "mime_type": "image/png",
  "created_by": "6ad1ab0a-73ff-4ac1-b9e4-cdb312f71f13",
  "created_at": 1577836800,
}

Copy
Copied!
POST
/chat-messages/:task_id/stop
Stop Generate
Only supported in streaming mode.

Path
task_id (string) Task ID, can be obtained from the streaming chunk return
Request Body
user (string) Required User identifier, used to define the identity of the end-user, must be consistent with the user passed in the send message interface.
Response
result (string) Always returns "success"
Request Example
Request
POST
/chat-messages/:task_id/stop
curl -X POST 'https://trendgpt-difytest.testenvs.click/v1/chat-messages/:task_id/stop' \
-H 'Authorization: Bearer {api_key}' \
-H 'Content-Type: application/json' \
--data-raw '{"user": "abc-123"}'

Copy
Copied!
Response Example
Response
{
  "result": "success"
}

Copy
Copied!
POST
/messages/:message_id/feedbacks
Message Feedback
End-users can provide feedback messages, facilitating application developers to optimize expected outputs.

Path
Name
message_id
Type
string
Description
Message ID

Request Body
Name
rating
Type
string
Description
Upvote as like, downvote as dislike, revoke upvote as null

Name
user
Type
string
Description
User identifier, defined by the developer's rules, must be unique within the application.

Name
content
Type
string
Description
The specific content of message feedback.

Response
result (string) Always returns "success"
Request
POST
/messages/:message_id/feedbacks
curl -X POST 'https://trendgpt-difytest.testenvs.click/v1/messages/:message_id/feedbacks \
 --header 'Authorization: Bearer {api_key}' \
--header 'Content-Type: application/json' \
--data-raw '{
    "rating": "like",
    "user": "abc-123",
    "content": "message feedback information"
}'

Copy
Copied!
Response
{
  "result": "success"
}

Copy
Copied!
GET
/messages/{message_id}/suggested
Next Suggested Questions
Get next questions suggestions for the current message

Path Params
Name
message_id
Type
string
Description
Message ID

Query
Name
user
Type
string
Description
User identifier, used to define the identity of the end-user for retrieval and statistics. Should be uniquely defined by the developer within the application.

Request
GET
/messages/{message_id}/suggested
curl --location --request GET 'https://trendgpt-difytest.testenvs.click/v1/messages/{message_id}/suggested?user=abc-123& \
--header 'Authorization: Bearer ENTER-YOUR-SECRET-KEY' \
--header 'Content-Type: application/json'

Copy
Copied!
Response
{
  "result": "success",
  "data": [
        "a",
        "b",
        "c"
    ]
}

Copy
Copied!
GET
/messages
Get Conversation History Messages
Returns historical chat records in a scrolling load format, with the first page returning the latest {limit} messages, i.e., in reverse order.

Query
Name
conversation_id
Type
string
Description
Conversation ID

Name
user
Type
string
Description
User identifier, used to define the identity of the end-user for retrieval and statistics. Should be uniquely defined by the developer within the application.

Name
first_id
Type
string
Description
The ID of the first chat record on the current page, default is null.

Name
limit
Type
int
Description
How many chat history messages to return in one request, default is 20.

Response
data (array[object]) Message list
id (string) Message ID
conversation_id (string) Conversation ID
inputs (object) User input parameters.
query (string) User input / question content.
message_files (array[object]) Message files
id (string) ID
type (string) File type, image for images
url (string) Preview image URL
belongs_to (string) belongs to，user or assistant
agent_thoughts (array[object]) Agent thought（Empty if it's a Basic Assistant）
id (string) Agent thought ID, every iteration has a unique agent thought ID
message_id (string) Unique message ID
position (int) Position of current agent thought, each message may have multiple thoughts in order.
thought (string) What LLM is thinking about
observation (string) Response from tool calls
tool (string) A list of tools represents which tools are called，split by ;
tool_input (string) Input of tools in JSON format. Like: {"dalle3": {"prompt": "a cute cat"}}.
created_at (int) Creation timestamp, e.g., 1705395332
message_files (array[string]) Refer to message_file event
file_id (string) File ID
answer (string) Response message content
created_at (timestamp) Creation timestamp, e.g., 1705395332
feedback (object) Feedback information
rating (string) Upvote as like / Downvote as dislike
retriever_resources (array[RetrieverResource]) Citation and Attribution List
has_more (bool) Whether there is a next page
limit (int) Number of returned items, if input exceeds system limit, returns system limit amount
Request
GET
/messages
curl -X GET 'https://trendgpt-difytest.testenvs.click/v1/messages?user=abc-123&conversation_id='\
 --header 'Authorization: Bearer {api_key}'

Copy
Copied!
Response Example (Basic Assistant)
Response
{
  "limit": 20,
  "has_more": false,
  "data": [
    {
        "id": "a076a87f-31e5-48dc-b452-0061adbbc922",
        "conversation_id": "cd78daf6-f9e4-4463-9ff2-54257230a0ce",
        "inputs": {
            "name": "dify"
        },
        "query": "iphone 13 pro",
        "answer": "The iPhone 13 Pro, released on September 24, 2021, features a 6.1-inch display with a resolution of 1170 x 2532. It is equipped with a Hexa-core (2x3.23 GHz Avalanche + 4x1.82 GHz Blizzard) processor, 6 GB of RAM, and offers storage options of 128 GB, 256 GB, 512 GB, and 1 TB. The camera is 12 MP, the battery capacity is 3095 mAh, and it runs on iOS 15.",
        "message_files": [],
        "feedback": null,
        "retriever_resources": [
            {
                "position": 1,
                "dataset_id": "101b4c97-fc2e-463c-90b1-5261a4cdcafb",
                "dataset_name": "iPhone",
                "document_id": "8dd1ad74-0b5f-4175-b735-7d98bbbb4e00",
                "document_name": "iPhone List",
                "segment_id": "ed599c7f-2766-4294-9d1d-e5235a61270a",
                "score": 0.98457545,
                "content": "\"Model\",\"Release Date\",\"Display Size\",\"Resolution\",\"Processor\",\"RAM\",\"Storage\",\"Camera\",\"Battery\",\"Operating System\"\n\"iPhone 13 Pro Max\",\"September 24, 2021\",\"6.7 inch\",\"1284 x 2778\",\"Hexa-core (2x3.23 GHz Avalanche + 4x1.82 GHz Blizzard)\",\"6 GB\",\"128, 256, 512 GB, 1TB\",\"12 MP\",\"4352 mAh\",\"iOS 15\""
            }
        ],
        "agent_thoughts": [],
        "created_at": 1705569239,
    }
  ]
}

Copy
Copied!
Response Example (Agent Assistant)
Response
{
    "limit": 20,
    "has_more": false,
    "data": [
        {
            "id": "d35e006c-7c4d-458f-9142-be4930abdf94",
            "conversation_id": "957c068b-f258-4f89-ba10-6e8a0361c457",
            "inputs": {},
            "query": "draw a cat",
            "answer": "I have generated an image of a cat for you. Please check your messages to view the image.",
            "message_files": [
                {
                    "id": "976990d2-5294-47e6-8f14-7356ba9d2d76",
                    "type": "image",
                    "url": "http://127.0.0.1:5001/files/tools/976990d2-5294-47e6-8f14-7356ba9d2d76.png?timestamp=1705988524&nonce=55df3f9f7311a9acd91bf074cd524092&sign=z43nMSO1L2HBvoqADLkRxr7Biz0fkjeDstnJiCK1zh8=",
                    "belongs_to": "assistant"
                }
            ],
            "feedback": null,
            "retriever_resources": [],
            "created_at": 1705988187,
            "agent_thoughts": [
                {
                    "id": "592c84cf-07ee-441c-9dcc-ffc66c033469",
                    "chain_id": null,
                    "message_id": "d35e006c-7c4d-458f-9142-be4930abdf94",
                    "position": 1,
                    "thought": "",
                    "tool": "dalle2",
                    "tool_input": "{\"dalle2\": {\"prompt\": \"cat\"}}",
                    "created_at": 1705988186,
                    "observation": "image has been created and sent to user already, you should tell user to check it now.",
                    "files": [
                        "976990d2-5294-47e6-8f14-7356ba9d2d76"
                    ]
                },
                {
                    "id": "73ead60d-2370-4780-b5ed-532d2762b0e5",
                    "chain_id": null,
                    "message_id": "d35e006c-7c4d-458f-9142-be4930abdf94",
                    "position": 2,
                    "thought": "I have generated an image of a cat for you. Please check your messages to view the image.",
                    "tool": "",
                    "tool_input": "",
                    "created_at": 1705988199,
                    "observation": "",
                    "files": []
                }
            ]
        }
    ]
}

Copy
Copied!
GET
/conversations
Get Conversations
Retrieve the conversation list for the current user, defaulting to the most recent 20 entries.

Query
Name
user
Type
string
Description
User identifier, used to define the identity of the end-user for retrieval and statistics. Should be uniquely defined by the developer within the application.

Name
last_id
Type
string
Description
(Optional) The ID of the last record on the current page, default is null.

Name
limit
Type
int
Description
(Optional) How many records to return in one request, default is the most recent 20 entries. Maximum 100, minimum 1.

Name
sort_by
Type
string
Description
(Optional) Sorting Field, Default: -updated_at (sorted in descending order by update time)

Available Values: created_at, -created_at, updated_at, -updated_at
The symbol before the field represents the order or reverse, "-" represents reverse order.
Response
data (array[object]) List of conversations
id (string) Conversation ID
name (string) Conversation name, by default, is a snippet of the first question asked by the user in the conversation.
inputs (object) User input parameters.
status (string) Conversation status
introduction (string) Introduction
created_at (timestamp) Creation timestamp, e.g., 1705395332
updated_at (timestamp) Update timestamp, e.g., 1705395332
has_more (bool)
limit (int) Number of entries returned, if input exceeds system limit, system limit number is returned
Request
GET
/conversations
curl -X GET 'https://trendgpt-difytest.testenvs.click/v1/conversations?user=abc-123&last_id=&limit=20' \
 --header 'Authorization: Bearer {api_key}'

Copy
Copied!
Response
{
  "limit": 20,
  "has_more": false,
  "data": [
    {
      "id": "10799fb8-64f7-4296-bbf7-b42bfbe0ae54",
      "name": "New chat",
      "inputs": {
          "book": "book",
          "myName": "Lucy"
      },
      "status": "normal",
      "created_at": 1679667915,
      "updated_at": 1679667915
    },
    {
      "id": "hSIhXBhNe8X1d8Et"
      // ...
    }
  ]
}

Copy
Copied!
DELETE
/conversations/:conversation_id
Delete Conversation
Delete a conversation.

Path
conversation_id (string) Conversation ID
Request Body
Name
user
Type
string
Description
The user identifier, defined by the developer, must ensure uniqueness within the application.

Response
result (string) Always returns "success"
Request
DELETE
/conversations/:conversation_id
curl -X DELETE 'https://trendgpt-difytest.testenvs.click/v1/conversations/:conversation_id' \
--header 'Authorization: Bearer {api_key}' \
--header 'Content-Type: application/json' \
--data-raw '{ 
 "user": "abc-123"
}'

Copy
Copied!
Response
{
  "result": "success"
}

Copy
Copied!
POST
/conversations/:conversation_id/name
Conversation Rename
Request Body
Rename the session, the session name is used for display on clients that support multiple sessions.

Path
conversation_id (string) Conversation ID
Name
name
Type
string
Description
(Optional) The name of the conversation. This parameter can be omitted if auto_generate is set to true.

Name
auto_generate
Type
bool
Description
(Optional) Automatically generate the title, default is false

Name
user
Type
string
Description
The user identifier, defined by the developer, must ensure uniqueness within the application.

Response
id (string) Conversation ID
name (string) Conversation name
inputs (object) User input parameters
status (string) Conversation status
introduction (string) Introduction
created_at (timestamp) Creation timestamp, e.g., 1705395332
updated_at (timestamp) Update timestamp, e.g., 1705395332
Request
POST
/conversations/:conversation_id/name
curl -X POST 'https://trendgpt-difytest.testenvs.click/v1/conversations/:conversation_id/name' \
--header 'Authorization: Bearer {api_key}' \
--header 'Content-Type: application/json' \
--data-raw '{ 
 "name": "", 
 "auto_generate": true, 
 "user": "abc-123"
}'

Copy
Copied!
Response
{
    "id": "cd78daf6-f9e4-4463-9ff2-54257230a0ce",
    "name": "Chat vs AI",
    "inputs": {},
    "status": "normal",
    "introduction": "",
    "created_at": 1705569238,
    "updated_at": 1705569238
}

Copy
Copied!
POST
/audio-to-text
Speech to Text
This endpoint requires a multipart/form-data request.

Request Body
Name
file
Type
file
Description
Audio file. Supported formats: ['mp3', 'mp4', 'mpeg', 'mpga', 'm4a', 'wav', 'webm'] File size limit: 15MB

Name
user
Type
string
Description
User identifier, defined by the developer's rules, must be unique within the application.

Response
text (string) Output text
Request
POST
/audio-to-text
curl -X POST 'https://trendgpt-difytest.testenvs.click/v1/audio-to-text' \
--header 'Authorization: Bearer {api_key}' \
--form 'file=@localfile;type=audio/[mp3|mp4|mpeg|mpga|m4a|wav|webm]'

Copy
Copied!
Response
{
  "text": ""
}

Copy
Copied!
POST
/text-to-audio
Text to Audio
Text to speech.

Request Body
Name
message_id
Type
str
Description
For text messages generated by Dify, simply pass the generated message-id directly. The backend will use the message-id to look up the corresponding content and synthesize the voice information directly. If both message_id and text are provided simultaneously, the message_id is given priority.

Name
text
Type
str
Description
Speech generated content。

Name
user
Type
string
Description
The user identifier, defined by the developer, must ensure uniqueness within the app.

Request
POST
/text-to-audio
curl --location --request POST 'https://trendgpt-difytest.testenvs.click/v1/text-to-audio' \
--header 'Authorization: Bearer ENTER-YOUR-SECRET-KEY' \
--form 'text=Hello Dify;user=abc-123;message_id=5ad4cb98-f0c7-4085-b384-88c403be6290

Copy
Copied!
headers
{
  "Content-Type": "audio/wav"
}

Copy
Copied!
GET
/info
Get Application Basic Information
Used to get basic information about this application

Response
name (string) application name
description (string) application description
tags (array[string]) application tags
Request
GET
/info
curl -X GET 'https://trendgpt-difytest.testenvs.click/v1/info' \
-H 'Authorization: Bearer {api_key}'

Copy
Copied!
Response
{
  "name": "My App",
  "description": "This is my app.",
  "tags": [
    "tag1",
    "tag2"
  ]
}

Copy
Copied!
GET
/parameters
Get Application Parameters Information
Used at the start of entering the page to obtain information such as features, input parameter names, types, and default values.

Query
Name
user
Type
string
Description
User identifier, defined by the developer's rules, must be unique within the application.

Response
opening_statement (string) Opening statement
suggested_questions (array[string]) List of suggested questions for the opening
suggested_questions_after_answer (object) Suggest questions after enabling the answer.
enabled (bool) Whether it is enabled
speech_to_text (object) Speech to text
enabled (bool) Whether it is enabled
retriever_resource (object) Citation and Attribution
enabled (bool) Whether it is enabled
annotation_reply (object) Annotation reply
enabled (bool) Whether it is enabled
user_input_form (array[object]) User input form configuration
text-input (object) Text input control
label (string) Variable display label name
variable (string) Variable ID
required (bool) Whether it is required
default (string) Default value
paragraph (object) Paragraph text input control
label (string) Variable display label name
variable (string) Variable ID
required (bool) Whether it is required
default (string) Default value
select (object) Dropdown control
label (string) Variable display label name
variable (string) Variable ID
required (bool) Whether it is required
default (string) Default value
options (array[string]) Option values
file_upload (object) File upload configuration
image (object) Image settings Currently only supports image types: png, jpg, jpeg, webp, gif
enabled (bool) Whether it is enabled
number_limits (int) Image number limit, default is 3
transfer_methods (array[string]) List of transfer methods, remote_url, local_file, must choose one
system_parameters (object) System parameters
file_size_limit (int) Document upload size limit (MB)
image_file_size_limit (int) Image file upload size limit (MB)
audio_file_size_limit (int) Audio file upload size limit (MB)
video_file_size_limit (int) Video file upload size limit (MB)
Request
GET
/parameters
 curl -X GET 'https://trendgpt-difytest.testenvs.click/v1/parameters'

Copy
Copied!
Response
{
  "opening_statement": "Hello!",
  "suggested_questions_after_answer": {
      "enabled": true
  },
  "speech_to_text": {
      "enabled": true
  },
  "retriever_resource": {
      "enabled": true
  },
  "annotation_reply": {
      "enabled": true
  },
  "user_input_form": [
      {
          "paragraph": {
              "label": "Query",
              "variable": "query",
              "required": true,
              "default": ""
          }
      }
  ],
  "file_upload": {
      "image": {
          "enabled": false,
          "number_limits": 3,
          "detail": "high",
          "transfer_methods": [
              "remote_url",
              "local_file"
          ]
      }
  },
  "system_parameters": {
      "file_size_limit": 15,
      "image_file_size_limit": 10,
      "audio_file_size_limit": 50,
      "video_file_size_limit": 100
  }
}

Copy
Copied!
GET
/meta
Get Application Meta Information
Used to get icons of tools in this application

Response
tool_icons(object[string]) tool icons
tool_name (string)
icon (object|string)
(object) icon object
background (string) background color in hex format
content(string) emoji
(string) url of icon
Request
GET
/meta
curl -X GET 'https://trendgpt-difytest.testenvs.click/v1/meta' \
-H 'Authorization: Bearer {api_key}'

Copy
Copied!
Response
{
  "tool_icons": {
    "dalle2": "https://cloud.dify.ai/console/api/workspaces/current/tool-provider/builtin/dalle/icon",
    "api_tool": {
      "background": "#252525",
      "content": "😁"
    }
  }
}

Copy
Copied!
GET
/apps/annotations
Get Annotation List
Query
Name
page
Type
string
Description
Page number

Name
limit
Type
string
Description
Number of items returned, default 20, range 1-100

Request
GET
/apps/annotations
curl --location --request GET 'undefined/apps/annotations?page=1&limit=20' \
--header 'Authorization: Bearer {api_key}'

Copy
Copied!
Response
{
  "data": [
    {
      "id": "69d48372-ad81-4c75-9c46-2ce197b4d402",
      "question": "What is your name?",
      "answer": "I am Dify.",
      "hit_count": 0,
      "created_at": 1735625869
    }
  ],
  "has_more": false,
  "limit": 20,
  "total": 1,
  "page": 1
}

Copy
Copied!
POST
/apps/annotations
Create Annotation
Query
Name
question
Type
string
Description
Question

Name
answer
Type
string
Description
Answer

Request
POST
/apps/annotations
curl --location --request POST 'undefined/apps/annotations' \
--header 'Authorization: Bearer {api_key}' \
--header 'Content-Type: application/json' \
--data-raw '{"question": "What is your name?","answer": "I am Dify."}'

Copy
Copied!
Response
{
  {
    "id": "69d48372-ad81-4c75-9c46-2ce197b4d402",
    "question": "What is your name?",
    "answer": "I am Dify.",
    "hit_count": 0,
    "created_at": 1735625869
  }
}

Copy
Copied!
PUT
/apps/annotations/{annotation_id}
Update Annotation
Query
Name
annotation_id
Type
string
Description
Annotation ID

Name
question
Type
string
Description
Question

Name
answer
Type
string
Description
Answer

Request
PUT
/apps/annotations/{annotation_id}
curl --location --request POST 'undefined/apps/annotations/{annotation_id}' \
--header 'Authorization: Bearer {api_key}' \
--header 'Content-Type: application/json' \
--data-raw '{"question": "What is your name?","answer": "I am Dify."}'

Copy
Copied!
Response
{
  {
    "id": "69d48372-ad81-4c75-9c46-2ce197b4d402",
    "question": "What is your name?",
    "answer": "I am Dify.",
    "hit_count": 0,
    "created_at": 1735625869
  }
}

Copy
Copied!
DELETE
/apps/annotations/{annotation_id}
Delete Annotation
Query
Name
annotation_id
Type
string
Description
Annotation ID

Request
PUT
/apps/annotations/{annotation_id}
curl --location --request DELETE 'undefined/apps/annotations/{annotation_id}' \
--header 'Authorization: Bearer {api_key}' \
--header 'Content-Type: application/json'

Copy
Copied!
Response
{"result": "success"}

Copy
Copied!
POST
/apps/annotation-reply/{action}
Initial Annotation Reply Settings
Query
Name
action
Type
string
Description
Action, can only be 'enable' or 'disable'

Name
embedding_model_provider
Type
string
Description
Specified embedding model provider, must be set up in the system first, corresponding to the provider field(Optional)

Name
embedding_model
Type
string
Description
Specified embedding model, corresponding to the model field(Optional)

Name
score_threshold
Type
number
Description
The similarity threshold for matching annotated replies. Only annotations with scores above this threshold will be recalled.

The provider and model name of the embedding model can be obtained through the following interface: v1/workspaces/current/models/model-types/text-embedding. For specific instructions, see: Maintain Knowledge Base via API. The Authorization used is the Dataset API Token.

Request
POST
/apps/annotation-reply/{action}
curl --location --request POST 'undefined/apps/annotation-reply/{action}' \
--header 'Authorization: Bearer {api_key}' \
--header 'Content-Type: application/json' \
--data-raw '{"score_threshold": 0.9, "embedding_provider_name": "zhipu", "embedding_model_name": "embedding_3"}'

Copy
Copied!
Response
{
  "job_id": "b15c8f68-1cf4-4877-bf21-ed7cf2011802",
  "job_status": "waiting"
}

Copy
Copied!
This interface is executed asynchronously, so it will return a job_id. You can get the final execution result by querying the job status interface.

GET
/apps/annotation-reply/{action}/status/{job_id}
Query Initial Annotation Reply Settings Task Status
Query
Name
action
Type
string
Description
Action, can only be 'enable' or 'disable', must be the same as the action in the initial annotation reply settings interface

Name
job_id
Type
string
Description
Job ID,

Request
GET
/apps/annotations
curl --location --request GET 'undefined/apps/annotation-reply/{action}/status/{job_id}' \
--header 'Authorization: Bearer {api_key}'

Copy
Copied!
Response
{
  "job_id": "b15c8f68-1cf4-4877-bf21-ed7cf2011802",
  "job_status": "waiting",
  "error_msg": ""
}