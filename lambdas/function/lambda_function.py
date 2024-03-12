import aws_xray_sdk.core
import boto3
import requests
import os
import base64
import io
import mimetypes

# Initialize the AWS X-Ray SDK
aws_xray_sdk.core.patch_all()

def lambda_handler(event, context):
    # Start a new X-Ray segment
    with aws_xray_sdk.core.xray_recorder.capture('get_api_images'):
        # Create an S3 client
        session = boto3.Session()
        s3 = session.resource('s3')
        bucket_name = os.getenv('BUCKET_NAME')

        action = event.get('action')
        if action == 'api2':
            # Call the Dog API
            with aws_xray_sdk.core.xray_recorder.capture('call_dog_api'):
                # Define the endpoint for the Dog API
                endpoint = 'https://dog.ceo/api/breeds/image/random'
                # Make a GET request to the Dog API
                response = requests.get(endpoint)
                # Get the image URL from the response
                image_url = response.json()['message']
                # Get the name of the image
                image_name = str(response.json()['message']).split('/')[-1]
                # Download the image from the URL
                image = requests.get(image_url, stream=True).content
        else:
            # Call the Fox API
            with aws_xray_sdk.core.xray_recorder.capture('call_fox_api'):
                # Define the endpoint for the Dog API
                endpoint = 'https://randomfox.ca/floof/'
                # Make a GET request to the Dog API
                response = requests.get(endpoint)
                # Get the image URL from the response
                image_url = response.json()['image']
                # Get the name of the image
                image_name = str(response.json()['image']).split('/')[-1]
                # Download the image from the URL
                image = requests.get(image_url, stream=True).content
            
        # Save the weather data to S3
        with aws_xray_sdk.core.xray_recorder.capture('save_img_to_s3'):
            contenttype = mimetypes.types_map['.' + image_name.split('.')[-1]]
            bucket = s3.Bucket(bucket_name)
            bucket.upload_fileobj(io.BytesIO(image), image_name, ExtraArgs={'ContentType': contenttype})

    # Generate a response with the image in the body
    response = {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'image/jpeg'
        },
        'body': base64.b64encode(image),
        'isBase64Encoded': True
    }
    return response
        
    