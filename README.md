# Serverless STNS API Templates

サーバーレスな [STNS (Simple TOML Name Service)](https://stns.jp/) の API を AWS で構築するための Terraform テンプレートです。

ユーザーリポジトリは `DynamoDB` で、バックエンドは `API Gateway` + `Lambda` で実装しています。

## Concept

* VPC 内からのアクセスを想定して Private API としてデプロイします。
* サーバーごと (厳密には API Token ごと) に認証可能なアカウントを制御するため Custom Authorizer を利用します。

## Why not SAM ?

当初 SAM (Serverless Application Model) で実装していましたが、Private API 用の Hack が必要な点や、 STNS クライアントの都合（`X-API-TOKEN`ヘッダを使えない）により SAM を利用するのが困難だったため、Terraform のテンプレートにしています。  
SAM がもろもろ対応したら SAM に載せ替えます。

## Requirements / Setup

* Ruby 2.5.0
* terraform >= '0.11.10'
* terraform-aws-provider >= '1.59.0'
* find コマンド (Lambda ソースを一覧するために利用)
* md5 コマンド (Lambda ソースの更新チェックに利用)
* zip コマンド (Lambda ソースのアーカイブに利用)

```terraform
provider "aws" {
  region = "ap-northeast-1"
  version = "1.59.0"
}

module "stns" {
  source  = "https://github.com/QLife-Inc/aws-stns-serverless-api.git"
  api_key = "hogehoge"
  api_policy_json <<EOF
  {
     "Version": "2012-10-17",
     "Statement": [
         {
             "Effect": "Deny",
             "Principal": "*",
             "Action": "execute-api:Invoke",
             "Resource": "execute-api:/*/*/*",
             "Condition": {
                 "StringNotEquals": {
                     "aws:sourceVpce": "${vpce_id}"
                 }
             }
         },
         {
             "Effect": "Allow",
             "Principal": "*",
             "Action": "execute-api:Invoke",
             "Resource": "execute-api:/*/*/*"
         }
     ]
  }
EOF
  # api_policy_file = "/path/to/resource_policy.json"
  # api_name = "stns-api"
  # stage_name = "v2"
  # user_table_name = "stns-users"
  # group_table_name = "stns-groups"
  # auth_table_name = "stns-authorizations"
  # log_retention_in_days = 30
  # base_tags = {
  #   "Environment" = "production"
  #   "CreatedBy" = "terraform"
  # }
}
```

`terraform apply` で API をデプロイすると、以下の出力が得られます。

```
Outputs:

stns_api_url = https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/v2
```

上記 URL を `/etc/stns/client/stns.conf` の `api_endpoint` に指定してください。

## Parameters

### Required parameters

#### api_key

内部で利用する API Gateway の API キーです。適当な英数字を設定してください。

> API Key は Custom Authorizer から API Gateway に渡されるため、内部でしか利用されません(`X-API-TOKEN`ヘッダを利用しません)。これは、`libnss-stns-v2` から `X-API-TOKEN` ヘッダを渡せないための回避策で、`Authorization` ヘッダを Custom Authorizer で解析して API Key (固定値) を API Gateway に渡しています。  

> そのため、本来であれば値を外部から渡す必要もないのですが、 Terraform で作成しようとしたら循環参照になってしまったため、外部から値を渡す必要があります。作成した API Key の値は Custom Authorizer によりセットされるため、クライアントから意識することはないです。  

> そもそも API Key が必要なのか、というところですが、API Gateway の Private API は API Key がないとどうやっても 403 Forbidden になってしまったため、こうしています（なくても通るならやり方教えてください）。

#### api_policy_file, api_policy_json

`api_policy_file` か `api_policy_json` のいずれかを指定してください。 `api_policy_json` は API のリソースポリシーです。 `SourceVpc` や `SourceVpce` を利用して Private API にアクセスするための API リソースポリシーを JSON で指定します。  
`api_policy_file` は JSON ファイルへのパスです。どちらも指定しなかった場合、`terraform apply` 実行時にエラーになります。

### Optional parameters

#### api_name

API Gateway にデプロイされる API のリソース名。デフォルトは `stns-api` 。

#### stage_name

API Gateway のデプロイステージ名で、URL のパスプレフィクスとなります。デフォルトは `v2` 。

#### user_table_name

作成されるユーザーアカウント用の DynamoDB テーブル名です。デフォルトは `stns-users` 。

#### group_table_name

作成されるユーザーグループ用の DynamoDB テーブル名です。デフォルトは `stns-groups` 。

#### auth_table_name

API トークンごとのアカウント認可用の DynamoDB テーブル名です。デフォルトは `stns-authorizations` 。

#### log_retention_in_days

Lambda 関数のログを CloudWatch Logs に保存する日数です。デフォルトは 30 日。

#### base_tags

DynamoDB テーブルや IAM ロールなどに設定されるタグを Map で指定します。デフォルトは空。

## DynamoDB Table Schema

現状、[STNS API のインターフェース](https://stns.jp/en/interface) に合わせたテーブル構造です。関連などをデータ構造で表現する予定は今のところありません。

DynamoDB の項目登録はサポートしていません。マネジメントコンソールで以下の内容で登録してください。

### stns-users

必須項目は `name` と `id`, および 1 つ以上の `keys` です。

```json
{
  "name": "hoge",
  "id": 2001,
  "password": "",
  "directory": "/home/hoge",
  "shell": "/bin/bash",
  "group_id": 2001,
  "keys": [
    "ssh-rsa xxxxxxx ..."
  ],
  "geos": "hogehoge"
}
```

### stns-groups

```json
{
  "name": "hoge",
  "id": 2001,
  "users": [
    "hoge"
  ]
}
```

### stns-authorizations

STNS クライアントが送出する `Authorization` ヘッダに設定されるトークンに紐づく認可情報を格納するテーブルです（まだ適当です、すいません）。

このテーブルにある token を `/etc/stns/client/stns.conf` の `auth_token` に指定してください。指定したトークンによって認証可能なアカウントを振り分けます。

トークンごとに認可アカウントを絞り込む場合は `users` や `groups` に認可を与えるユーザー名、グループ名を指定します。

`users` が 未設定, `null` もしくは空 `[]` の場合は `stns-users` テーブルのユーザーがすべてログイン可能となります。同様に、 `groups` が空の場合は `stns-groups` テーブルのグループがすべてログイン可能です。

```json
{
  "token": "xxxxx ...",
  "users": [
    "hoge"
  ],
  "groups": [
    "engineers",
    "designers"
  ]
}
```

## Development

とりあえず動けばいいやってことで、実装はかなり適当です。

DynamoDB の API は `aws-record` gem を利用しています。

API の実装は `Sinatra` です。AWS のサンプル (https://github.com/aws-samples/serverless-sinatra-sample) をほぼそのまま流用しています。

Custom Authorizer は適当に Ruby で実装しています。
