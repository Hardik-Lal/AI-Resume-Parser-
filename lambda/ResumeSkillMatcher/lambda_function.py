import os
import boto3

s3 = boto3.client('s3')
textract = boto3.client('textract')
comprehend = boto3.client('comprehend')

REQUIRED_SKILLS = os.environ['REQUIRED_SKILLS'].split(',')

def lambda_handler(event, context):
    record = event['Records'][0]['s3']
    bucket = record['bucket']['name']
    key = record['object']['key']

    # 1. Download & extract text
    tmp = '/tmp/input'
    s3.download_file(bucket, key, tmp)
    with open(tmp, 'rb') as f:
        doc = f.read()
    tex_resp = textract.detect_document_text(Document={'Bytes': doc})
    text = ' '.join([item['DetectedText'] for item in tex_resp['Blocks'] if item['BlockType']=='LINE'])

    # 2. Detect key phrases
    comp = comprehend.detect_key_phrases(Text=text, LanguageCode='en')
    phrases = [p['Text'].lower() for p in comp['KeyPhrases']]

    # 3. Match skills
    matched = [skill for skill in REQUIRED_SKILLS if skill.lower() in phrases]
    if matched:
        print(f"{key} matched skills: {matched}")
        # e.g., tag the object or copy to a folder
        s3.put_object_tagging(
            Bucket=bucket,
            Key=key,
            Tagging={'TagSet':[{'Key':'Matched','Value':','.join(matched)}]}
        )
    else:
        print(f"{key} had no matches.")