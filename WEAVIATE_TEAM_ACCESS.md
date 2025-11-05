# Weaviate Vector Store - Team Access Documentation

## Overview

This document provides instructions for accessing the Dify Weaviate vector store with read-only permissions for querying knowledge base content.

---

## Connection Details

| Parameter | Value |
|-----------|-------|
| **Base URL** | `https://trendgptdify.runtime.trendmicro.com/weaviate` |
| **API Key** | `UK5wySunCaNwYBNsXoo5T9cNeHcQPccvS91UB0mh4-4` |
| **Authentication** | Bearer token in `Authorization` header |
| **Access Level** | **Read-Only** (query only, no write operations) |
| **Network** | Internal only (VPN required if off-network) |

---

## Embedding Model Configuration

**IMPORTANT**: To perform vector searches, you must convert your queries to embeddings using:

| Parameter | Value |
|-----------|-------|
| **Model** | `text-embedding-3-large` |
| **Endpoint** | `https://api.rdsec.trendmicro.com/prod/aiendpoint/v1/` |
| **Dimensions** | 3072 |
| **API Format** | OpenAI-compatible |

---

## Authentication

### Weaviate Authentication

All Weaviate API requests must include the API key in the `Authorization` header:

```bash
Authorization: Bearer UK5wySunCaNwYBNsXoo5T9cNeHcQPccvS91UB0mh4-4
```

### RDSec Embedding API Authentication

For embedding generation, you'll need credentials for the RDSec AI endpoint. Contact the RDSec team for API access.

---

## Quick Start Examples

### 1. **Test Weaviate Connection**

```bash
curl -H "Authorization: Bearer UK5wySunCaNwYBNsXoo5T9cNeHcQPccvS91UB0mh4-4" \
  https://trendgptdify.runtime.trendmicro.com/weaviate/v1/meta
```

**Expected response**: Weaviate version and metadata

### 2. **List All Collections (Knowledge Bases)**

```bash
curl -H "Authorization: Bearer UK5wySunCaNwYBNsXoo5T9cNeHcQPccvS91UB0mh4-4" \
  https://trendgptdify.runtime.trendmicro.com/weaviate/v1/schema
```

**Response format**: Array of collection objects with class names like `Dataset_{uuid}_Node`

### 3. **Generate Embedding (RDSec Endpoint)**

```python
import requests

def get_embedding(text: str, api_key: str) -> list[float]:
    """Get embedding using RDSec AI endpoint"""
    url = "https://api.rdsec.trendmicro.com/prod/aiendpoint/v1/embeddings"

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": "text-embedding-3-large",
        "input": text
    }

    response = requests.post(url, json=payload, headers=headers)
    response.raise_for_status()

    return response.json()["data"][0]["embedding"]

# Example usage
query = "What is the return policy?"
embedding = get_embedding(query, api_key="your-rdsec-api-key")
print(f"Embedding dimensions: {len(embedding)}")  # Output: 3072
```

### 4. **Vector Similarity Search (Complete Example)**

```python
import weaviate
import requests

# Weaviate configuration
WEAVIATE_URL = "https://trendgptdify.runtime.trendmicro.com/weaviate"
WEAVIATE_KEY = "UK5wySunCaNwYBNsXoo5T9cNeHcQPccvS91UB0mh4-4"

# RDSec AI endpoint configuration
RDSEC_API_URL = "https://api.rdsec.trendmicro.com/prod/aiendpoint/v1/embeddings"
RDSEC_API_KEY = "your-rdsec-api-key"  # Get from RDSec team

# Initialize Weaviate client
weaviate_client = weaviate.Client(
    url=WEAVIATE_URL,
    auth_client_secret=weaviate.AuthApiKey(api_key=WEAVIATE_KEY),
    timeout_config=(5, 60)
)

# Get embedding for query
def get_embedding(text: str) -> list[float]:
    headers = {
        "Authorization": f"Bearer {RDSEC_API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "text-embedding-3-large",
        "input": text
    }
    response = requests.post(RDSEC_API_URL, json=payload, headers=headers)
    response.raise_for_status()
    return response.json()["data"][0]["embedding"]

# Search Weaviate (example: Vision One Documentation)
query = "What is the return policy?"
query_vector = get_embedding(query)

collection_name = "Vector_index_4437bcf1_3d24_466d_b935_8e6a35ec655a_Node"

result = (
    weaviate_client.query
    .get(collection_name, ["text", "doc_id", "document_id"])
    .with_near_vector({"vector": query_vector})
    .with_limit(4)
    .with_additional(["distance", "certainty"])
    .do()
)

# Process results
for item in result["data"]["Get"][collection_name]:
    score = 1 - item["_additional"]["distance"]
    print(f"Score: {score:.4f}")
    print(f"Text: {item['text'][:200]}")
    print()
```

### 5. **Full-Text Search (BM25 - No Embedding Required)**

```python
# Keyword-based search without embeddings (example: Vision One Documentation)
collection_name = "Vector_index_4437bcf1_3d24_466d_b935_8e6a35ec655a_Node"

result = (
    weaviate_client.query
    .get(collection_name, ["text", "doc_id"])
    .with_bm25(query="return policy", properties=["text"])
    .with_limit(4)
    .do()
)
```

### 6. **GraphQL Query (REST API)**

```bash
# Step 1: Get embedding via RDSec endpoint
EMBEDDING=$(curl -X POST https://api.rdsec.trendmicro.com/prod/aiendpoint/v1/embeddings \
  -H "Authorization: Bearer YOUR_RDSEC_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"text-embedding-3-large","input":"return policy"}' \
  | jq -c '.data[0].embedding')

# Step 2: Query Weaviate with embedding (example: Vision One Documentation)
curl -X POST \
  https://trendgptdify.runtime.trendmicro.com/weaviate/v1/graphql \
  -H 'Authorization: Bearer UK5wySunCaNwYBNsXoo5T9cNeHcQPccvS91UB0mh4-4' \
  -H 'Content-Type: application/json' \
  -d "{
    \"query\": \"{Get{Vector_index_4437bcf1_3d24_466d_b935_8e6a35ec655a_Node(limit:4 nearVector:{vector:$EMBEDDING}){text doc_id document_id _additional{distance}}}}\"
  }"
```

---

## Collection Names

Weaviate collections follow the naming convention: `Vector_index_{dataset_id}_Node`

**Example**: `Vector_index_4437bcf1_3d24_466d_b935_8e6a35ec655a_Node`

To find available collections, use the schema endpoint:
```bash
curl -H "Authorization: Bearer UK5wySunCaNwYBNsXoo5T9cNeHcQPccvS91UB0mh4-4" \
  https://trendgptdify.runtime.trendmicro.com/weaviate/v1/schema | jq '.classes[].class'
```

## Knowledge Base Mapping

There are **53 knowledge bases** available, organized by product category below.

### Vision One Product Family (4 collections)

| Collection Name | Knowledge Base Name | Description |
|----------------|---------------------|-------------|
| `Vector_index_4437bcf1_3d24_466d_b935_8e6a35ec655a_Node` | Vision One Documentation | Comprehensive user and administrator guides |
| `Vector_index_76ddac47_0cec_4109_b8a9_aedd1c259e2e_Node` | Vision One API (Beta) | Beta version API reference |
| `Vector_index_e6339aca_de01_4cbd_a5b2_8d226864bf3e_Node` | Vision One API (v3) | Version 3 API reference |
| `Vector_index_9427e3d3_c88e_4860_be3f_03d0b4a5243b_Node` | Vision One API (FedRAMP) | FedRAMP-compliant API reference |

### Apex Product Family (5 collections)

| Collection Name | Knowledge Base Name | Description |
|----------------|---------------------|-------------|
| `Vector_index_a3535673_2a70_420a_af83_fe9a20a8178a_Node` | Apex One Documentation | Endpoint protection for Windows |
| `Vector_index_02288a1d_f650_4457_91f7_29886da592d2_Node` | Apex One for Mac Documentation | Endpoint protection for macOS |
| `Vector_index_fd7b2215_de71_4861_b59e_e37b3fdbaac2_Node` | Apex One as a Service Documentation | Cloud-delivered endpoint protection |
| `Vector_index_2ddfc0af_5450_4022_81b0_973731f0e6b1_Node` | Apex Central Documentation | Centralized management console |
| `Vector_index_4cd2da33_1842_4101_85ce_429ef27d0ba6_Node` | Apex Central API | API reference for automation |

### Deep Security (2 collections)

| Collection Name | Knowledge Base Name | Description |
|----------------|---------------------|-------------|
| `Vector_index_ad4194ff_1980_4701_88e7_f480525bdcb7_Node` | Deep Security Documentation | Server and workload security platform |
| `Vector_index_7cc39224_a2c6_4763_934f_e903fc333b78_Node` | Deep Security API | API reference for automation |

### Deep Discovery (7 collections)

| Collection Name | Knowledge Base Name | Description |
|----------------|---------------------|-------------|
| `Vector_index_e9acbc9a_b96c_40d8_8adc_e2fd9f2dc926_Node` | Deep Discovery Documentation | Threat detection platform overview |
| `Vector_index_23d0149d_b996_4077_883d_b5975faad848_Node` | Deep Discovery Inspector Documentation | Network traffic inspection |
| `Vector_index_5596c29f_ef0e_420d_a417_74b68a3aeea3_Node` | Deep Discovery Analyzer Documentation | Advanced threat analysis |
| `Vector_index_6fdbe81e_a86d_43c4_95a2_d609457af666_Node` | Deep Discovery Email Inspector Documentation | Email threat detection |
| `Vector_index_dbc68d8a_a04f_4107_ab8b_6a509b114547_Node` | Deep Discovery Web Inspector Documentation | Web traffic inspection |
| `Vector_index_875721b4_c75f_4720_b9a3_4a795a89f8a5_Node` | Deep Discovery Network Analytics Documentation | Network behavior analysis |
| `Vector_index_fb5d0ee7_e71d_4cf0_9726_8c530a42ceab_Node` | Deep Discovery Director Documentation | Centralized management |

### Cloud One Product Family (9 collections)

| Collection Name | Knowledge Base Name | Description |
|----------------|---------------------|-------------|
| `Vector_index_b996055b_bdcb_4f93_8708_44b6606e7f43_Node` | Cloud One Workload Security Documentation | Cloud workload protection |
| `Vector_index_31eecee9_eb45_4c01_9fa1_78ef318d9f8f_Node` | Cloud One Workload Security API | API reference for automation |
| `Vector_index_970a8007_1e7d_4ca3_af33_cdbddbd3f73e_Node` | Cloud One Container Security Documentation | Container image scanning |
| `Vector_index_f3402f4a_7eee_4cda_9b4f_6b0621d75f4d_Node` | Cloud One File Storage Security Documentation | Cloud file storage scanning |
| `Vector_index_9de5f6c4_90e2_4f29_b415_0c47e661a6d3_Node` | Cloud One File Storage Security API | API reference for automation |
| `Vector_index_48eb4078_8a4b_4092_b0ca_7b208e99a671_Node` | Cloud One Conformity Documentation | Cloud security posture management |
| `Vector_index_f9757d47_94b1_4115_8eb1_31144a4e1937_Node` | Cloud One Conformity API | API reference for automation |
| `Vector_index_412d9d7c_48d3_4f5e_bde1_85ad3755a0d7_Node` | Cloud One Network Security Documentation | Cloud network security |
| `Vector_index_6ef00e13_42b0_49c3_9596_3860cae9224c_Node` | Cloud One Sentry Documentation | Runtime application self-protection |

### TippingPoint Product Family (4 collections)

| Collection Name | Knowledge Base Name | Description |
|----------------|---------------------|-------------|
| `Vector_index_e6add092_99aa_4eb8_b421_dbb16b120d01_Node` | TippingPoint Documentation | Threat protection system overview |
| `Vector_index_0403d241_2d4f_4113_930b_c2a108be1b70_Node` | TippingPoint TPS Documentation | Threat Protection System |
| `Vector_index_33bbcbdb_a5c3_4e17_a8aa_f14b219d00e6_Node` | TippingPoint SMS Documentation | Security Management System |
| `Vector_index_5d53c686_9c96_4bb5_b83d_506f6abd25f6_Node` | TippingPoint IPS Documentation | Intrusion Prevention System |

### TXOne Product Family (4 collections)

| Collection Name | Knowledge Base Name | Description |
|----------------|---------------------|-------------|
| `Vector_index_a7c4fd99_019e_4898_82bc_01c70eee0630_Node` | TXOne Documentation | OT/ICS security solutions |
| `Vector_index_27b9277a_b321_40cc_9ce6_fd4f7d73147a_Node` | TXOne OT Defense Console Documentation | Centralized OT security management |
| `Vector_index_ae38f488_0504_48da_8a8a_0ec212e79a4f_Node` | TXOne StellarEnforce Documentation | Application allowlisting for OT |
| `Vector_index_b22e5a75_c0c6_4d0b_936b_2d514a40cfb2_Node` | TXOne EdgeIPS Documentation | Industrial network intrusion prevention |

### Email & Messaging Security (7 collections)

| Collection Name | Knowledge Base Name | Description |
|----------------|---------------------|-------------|
| `Vector_index_49e440d9_d97b_4dd3_a9da_ec9d48ca76e5_Node` | Trend Micro Email Security Documentation | Independent email security platform |
| `Vector_index_256c01c7_b832_4e75_a0e7_4a89fe37675b_Node` | ScanMail Documentation | Email security platform overview |
| `Vector_index_b2da4f80_b094_4dd0_a7df_dd2c99b9d305_Node` | ScanMail for Domino Documentation | Email security for IBM Domino |
| `Vector_index_cfcab76e_6576_4e3d_8308_355dc85e1c84_Node` | ScanMail for Microsoft Exchange Documentation | Email security for Exchange |
| `Vector_index_e3106d9c_479f_4732_8575_e191dbc8dcc7_Node` | InterScan Messaging Security Documentation | Gateway-level email security |
| `Vector_index_5e8dee32_cc97_4c12_843f_64cb73ccd7e3_Node` | InterScan Messaging Suite for Linux Documentation | Email security for Linux |
| `Vector_index_86e8a946_46fc_4725_8fcc_18df23d05cc7_Node` | InterScan Messaging Virtual Appliance Documentation | Virtual appliance for email security |

### ServerProtect Product Family (6 collections)

| Collection Name | Knowledge Base Name | Description |
|----------------|---------------------|-------------|
| `Vector_index_80a7718e_1b74_4df4_87be_8bcad5f16763_Node` | ServerProtect Documentation | Server antivirus platform overview |
| `Vector_index_643a2123_af5d_43cb_a0be_224c25e189b7_Node` | ServerProtect for Windows/Novell Documentation | Protection for Windows/Novell |
| `Vector_index_3d257dc0_285f_4c2c_828f_9f4a07bd541a_Node` | ServerProtect for Linux Documentation | Protection for Linux |
| `Vector_index_10f73b7f_e0f4_430a_b35a_199b4c1082e0_Node` | ServerProtect for NetApp Documentation | Protection for NetApp storage |
| `Vector_index_1b228d9c_306a_48cc_b8a1_b037e512666b_Node` | ServerProtect for Storage Documentation | Protection for storage platforms |
| `Vector_index_da14d2c4_e2aa_4d1f_be7a_dee739570fba_Node` | ServerProtect for EMC Celerra Documentation | Protection for EMC Celerra |

### Other Products (6 collections)

| Collection Name | Knowledge Base Name | Description |
|----------------|---------------------|-------------|
| `Vector_index_9a06e544_615a_4a06_83e2_b80085f02d6c_Node` | Worry-Free Business Security Documentation | SMB endpoint and server security |
| `Vector_index_78f93ebf_cd79_427a_b616_b127cf84c5b8_Node` | Mobile Security for Enterprise Documentation | Mobile device security |
| `Vector_index_1435fb6f_a748_4618_b4e1_d39124e87373_Node` | PortalProtect for SharePoint Documentation | Security for SharePoint |
| `Vector_index_5cae6d84_ed26_4d98_bb96_04472287ca2a_Node` | Safe Lock Documentation | Ransomware protection |
| `Vector_index_e392b139_9c8c_4b12_a956_cbf8c43b7d24_Node` | TrendInsightKB Documentation | Internal knowledge base |

---

## Data Structure

Each document chunk (object) in Weaviate contains:

| Field | Type | Description |
|-------|------|-------------|
| `text` | string | Document chunk content |
| `doc_id` | string | Unique chunk identifier |
| `document_id` | string | Parent document ID |
| `dataset_id` | string | Knowledge base ID |
| `doc_hash` | string | Content hash for deduplication |

**Additional metadata** (from queries):
- `_additional.distance` - Cosine distance (0-2, lower = more similar)
- `_additional.certainty` - Similarity score (0-1, higher = better)
- `_additional.vector` - Embedding vector (3072 floats)

---

## Permissions

### ✅ **Allowed Operations**

- **Read collections**: `GET /v1/schema`
- **Query objects**: `POST /v1/graphql`
- **Vector search**: `nearVector` queries
- **Full-text search**: `bm25` queries
- **List objects**: `GET /v1/objects`
- **Get metadata**: `GET /v1/meta`

### ❌ **Denied Operations**

- **Create collections**: `POST /v1/schema`
- **Add objects**: `POST /v1/objects`
- **Update objects**: `PUT/PATCH /v1/objects/{id}`
- **Delete objects**: `DELETE /v1/objects/{id}`
- **Modify schema**: `PUT/DELETE /v1/schema/{class}`

**Attempting write operations will return `403 Forbidden`**

---

## Rate Limits & Best Practices

1. **Connection Pooling**: Reuse the Weaviate client instead of creating new connections
2. **Batch Queries**: Use GraphQL to query multiple collections in one request
3. **Timeouts**: Set reasonable timeouts (connect: 5s, read: 60s)
4. **Error Handling**: Handle `403` (permission denied), `404` (collection not found)
5. **Pagination**: Use `limit` and `offset` for large result sets
6. **RDSec API Limits**: Check with RDSec team for embedding API rate limits

---

## Troubleshooting

### **403 Forbidden Error (Weaviate)**

**Cause**: Attempting write operations with read-only key

**Solution**: Use only query/read operations

### **404 Not Found**

**Cause**: Collection name doesn't exist

**Solution**: Verify collection name using `/v1/schema` endpoint

### **401 Unauthorized (Weaviate)**

**Cause**: Missing or invalid API key

**Solution**: Ensure `Authorization: Bearer <key>` header is present

### **401 Unauthorized (RDSec Embedding API)**

**Cause**: Missing or invalid RDSec API credentials

**Solution**: Contact RDSec team for API access

### **Connection Timeout**

**Cause**: Network issues or VPN not connected

**Solution**: Verify VPN connection, check ingress status

### **Dimension Mismatch**

**Cause**: Using wrong embedding model (not `text-embedding-3-large`)

**Solution**: Always use `text-embedding-3-large` (3072 dimensions)

---

## Python Client Installation

```bash
pip install weaviate-client requests
```

---

## Complete Example: Search Workflow

```python
import weaviate
import requests
import os

# Configuration
WEAVIATE_URL = "https://trendgptdify.runtime.trendmicro.com/weaviate"
WEAVIATE_KEY = os.getenv("WEAVIATE_API_KEY", "UK5wySunCaNwYBNsXoo5T9cNeHcQPccvS91UB0mh4-4")  # Read-only key
RDSEC_API_URL = "https://api.rdsec.trendmicro.com/prod/aiendpoint/v1/embeddings"
RDSEC_API_KEY = os.getenv("RDSEC_API_KEY")  # Get from RDSec team

# Initialize Weaviate client
weaviate_client = weaviate.Client(
    url=WEAVIATE_URL,
    auth_client_secret=weaviate.AuthApiKey(api_key=WEAVIATE_KEY),
    timeout_config=(5, 60)
)

def get_embedding(text: str) -> list[float]:
    """Get embedding using RDSec AI endpoint (text-embedding-3-large)"""
    headers = {
        "Authorization": f"Bearer {RDSEC_API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "text-embedding-3-large",
        "input": text
    }
    response = requests.post(RDSEC_API_URL, json=payload, headers=headers)
    response.raise_for_status()
    return response.json()["data"][0]["embedding"]

def search_knowledge_base(collection_name: str, query: str, top_k: int = 4, score_threshold: float = 0.7):
    """Search knowledge base with vector similarity

    Args:
        collection_name: Full Weaviate collection name (e.g., 'Vector_index_4437bcf1_3d24_466d_b935_8e6a35ec655a_Node')
        query: Search query text
        top_k: Number of results to return
        score_threshold: Minimum similarity score (0-1)
    """
    # Get embedding
    query_vector = get_embedding(query)

    # Query Weaviate
    result = (
        weaviate_client.query
        .get(collection_name, ["text", "doc_id", "document_id"])
        .with_near_vector({"vector": query_vector})
        .with_limit(top_k)
        .with_additional(["distance"])
        .do()
    )

    # Process and filter results
    results = []
    for item in result["data"]["Get"][collection_name]:
        score = 1 - item["_additional"]["distance"]

        if score >= score_threshold:
            results.append({
                "text": item["text"],
                "doc_id": item["doc_id"],
                "document_id": item["document_id"],
                "score": score
            })

    return sorted(results, key=lambda x: x["score"], reverse=True)

def list_collections():
    """List all available Weaviate collections"""
    schema = weaviate_client.schema.get()
    collections = [cls["class"] for cls in schema.get("classes", [])]
    return collections

# Example usage
if __name__ == "__main__":
    # List available collections
    print("Available collections:")
    for collection in list_collections():
        print(f"  - {collection}")

    # Search example - Vision One Documentation
    collection = "Vector_index_4437bcf1_3d24_466d_b935_8e6a35ec655a_Node"  # Vision One Documentation
    query = "What is the return policy?"

    print(f"\nSearching '{collection}'")
    print(f"Query: '{query}'")
    results = search_knowledge_base(collection, query, top_k=5, score_threshold=0.7)

    print(f"\nFound {len(results)} results:\n")
    for i, result in enumerate(results, 1):
        print(f"Result {i}:")
        print(f"  Score: {result['score']:.4f}")
        print(f"  Document ID: {result['document_id']}")
        print(f"  Text: {result['text'][:200]}...")
        print()
```

---

## Support & Contact

- **RDSec AI Endpoint Access**: Contact RDSec team for API credentials
- **Weaviate Access Issues**: Contact Dify/TrendGPT infrastructure team
- **Collection/Dataset Questions**: Contact knowledge base administrators
- **Weaviate Documentation**: https://weaviate.io/developers/weaviate/api

---

## Security Notes

- **API Keys are Secret**: Do not commit to version control
- **Internal Access Only**: Requires VPN or internal network access
- **Read-Only**: Cannot modify or delete data
- **Audit Logging**: All access is logged for security monitoring
- **RDSec Endpoint**: Internal TrendMicro AI endpoint, not public OpenAI API

---

**Document Version**: 1.1
**Last Updated**: 2025-11-04
**Maintained By**: Ryan Duff (SE-NA)

**Changelog**:
- v1.1 (2025-11-04): Added comprehensive knowledge base mapping with all 53 collections organized by product category
- v1.0 (2025-01-04): Initial documentation release