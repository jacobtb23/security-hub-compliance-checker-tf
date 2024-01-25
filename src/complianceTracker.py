from curses import echo
import json
import boto3
import csv
import requests
import os
from datetime import date
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.discovery import MediaFileUpload
from oauth2client.service_account import ServiceAccountCredentials

#GLOBAL VARS
SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]
aws_client=boto3.client('ssm')

def lambda_handler(event, context):
    print ("==========================================================================================")
    print ("AWS CONFIG COMPLIANCE CHECKER")
    print ("==========================================================================================")
    try:
        current_date = date.today()
        print("Todays Date: " + str(current_date))
        # csv_name = '/tmp/' + str(current_date) + '.csv'
        write_data_to_tmp(current_date)
    except Exception as configCallcsvCreationError:
        print('[ERROR] Process aborted due to boto3 or CSV create error: ' + str(configCallcsvCreationError))
        sendSlackMessage(0)
        exit(1)
    print('==========================================================================================')
    tmpPopulated = checkTmpFolder()
    if tmpPopulated == True:
        print('All /tmp/ files present.')
        toGoogleSheet()
        deleteFiles()
    else:
        print('Not all /tmp/ files are present. Please try again.')
        sendSlackMessage(0)
        exit(2)
    print('==========================================================================================')

def appendCSVData(sheet):
    sheetID = aws_client.get_parameter(
        Name = 'spreadsheetID',
        WithDecryption = True
    )
    SPREADSHEET_ID = sheetID['Parameter']['Value']

    tab_security_control = 'ComplianceBySecurityControl!A2:D2'
    tab_accounts = 'ComplianceByAccount!A2:D2'
    tab_resources = 'ComplianceByResourceType!A2:D2'
    tab_severity = 'ComplianceBySeverity!A2:D2'

    last_sc_row = sheet.values().get(spreadsheetId=SPREADSHEET_ID, range=tab_security_control).execute().get('values')
    last_acct_row = sheet.values().get(spreadsheetId=SPREADSHEET_ID, range=tab_accounts).execute().get('values')
    last_res_row = sheet.values().get(spreadsheetId=SPREADSHEET_ID, range=tab_resources).execute().get('values')
    last_sev_row = sheet.values().get(spreadsheetId=SPREADSHEET_ID, range=tab_severity).execute().get('values')

    if last_sc_row is not None:
        tab_security_control_last = f'ComplianceBySecurityControl!A{len(last_sc_row) + 1}:D{len(last_sc_row) + 1}'
    else:
        tab_security_control_last = tab_security_control
    
    if last_acct_row is not None:
        tab_accounts_last = f'ComplianceByAccount!A{len(last_acct_row) + 1}:D{len(last_acct_row) + 1}'
    else:
        tab_accounts_last = tab_accounts
    
    if last_res_row is not None:
        tab_resources_last = f'ComplianceByResourceType!A{len(last_res_row) + 1}:D{len(last_res_row) + 1}'
    else:
        last_res_row = tab_resources
    
    if last_sev_row is not None:
        tab_severity_last = f'ComplianceBySeverity!A{len(last_sev_row) + 1}:D{len(last_sev_row) + 1}'
    else:
        tab_severity_last = tab_severity
    
    fileList = os.listdir('/tmp/')
    print(fileList)
    for file in fileList:
        if (file == 'failed_by_sc.csv') | (file == 'total_by_sc.csv'):
            print(file + ' --> ' + tab_security_control)
            data = []
            with open('/tmp/' + file, 'r') as csv_file:
                csv_reader = csv.reader(csv_file)
                for row in csv_reader:
                    data.append(row)      
            body = {'values' : data}
            res = sheet.values().append(
                spreadsheetId=SPREADSHEET_ID,
                range=tab_security_control_last,
                valueInputOption='USER_ENTERED',
                insertDataOption='INSERT_ROWS',
                body=body
            ).execute()
            print(res)
        elif (file == 'failed_by_acct.csv') | (file == 'total_by_acct.csv'):
            print(file + ' --> ' + tab_accounts)
            data = []
            with open('/tmp/' + file, 'r') as csv_file:
                csv_reader = csv.reader(csv_file)
                for row in csv_reader:
                    data.append(row)      
            body = {'values' : data}
            res = sheet.values().append(
                spreadsheetId=SPREADSHEET_ID,
                range=tab_accounts_last,
                valueInputOption='USER_ENTERED',
                insertDataOption='INSERT_ROWS',
                body=body
            ).execute()
            print(res)
        elif (file == 'failed_by_resource.csv') | (file == 'total_by_resource.csv'):
            data = []
            with open('/tmp/' + file, 'r') as csv_file:
                csv_reader = csv.reader(csv_file)
                for row in csv_reader:
                    data.append(row)      
            body = {'values' : data}
            res = sheet.values().append(
                spreadsheetId=SPREADSHEET_ID,
                range=tab_resources_last,
                valueInputOption='USER_ENTERED',
                insertDataOption='INSERT_ROWS',
                body=body
            ).execute()
            print(res)
        elif (file == 'total_by_sev.csv'):
            data = []
            with open('/tmp/' + file, 'r') as csv_file:
                csv_reader = csv.reader(csv_file)
                for row in csv_reader:
                    data.append(row)      
            body = {'values' : data}
            res = sheet.values().append(
                spreadsheetId=SPREADSHEET_ID,
                range=tab_severity_last,
                valueInputOption='USER_ENTERED',
                insertDataOption='INSERT_ROWS',
                body=body
            ).execute()
            print(res)
        else:
            print('You done messed up my friend...')

def toGoogleSheet():
    print('Pushing to Google Sheets...')
    aws_client=boto3.client('ssm')
    response1 = aws_client.get_parameter(
        Name = 'google-dirAPI-creds-sheets',
        WithDecryption = True
    )
    response2 = aws_client.get_parameter(
        Name = 'google-admin-email-sheets',
        WithDecryption = True
    )
    google_creds = json.loads(response1['Parameter']['Value'])
    admin_email = response2['Parameter']['Value']
    try: # Google JWT Setup...
        print('Aquiring Google JWT...')
        credentials = service_account.Credentials.from_service_account_info(google_creds,scopes=SCOPES,subject=admin_email)
        service = build('sheets', 'v4', credentials=credentials)
        sheet = service.spreadsheets()
        print("Tokens successfully created...")
    except Exception as GoogleJWTError:
        print("[ERROR] Google JWT Setup was aborted due to an error %s" % str(GoogleJWTError))
        sendSlackMessage(0)
        exit(1)

    try: # Push data to Google Sheets...
        appendCSVData(sheet)
        #sendSlackMessage(1)
    except Exception as appendCSVError:
        print("[ERROR] data was not sent to Google Sheets for appending: %s" % str(appendCSVError))
        sendSlackMessage(0)
        exit(2)

def sendSlackMessage(integer):
    currentDate = date.today()
    formattedDate = str(currentDate.strftime("%m-%d-%y"))
    webhook_url = '<slack_webhook>'
    if integer == 1:
        string = 'The lambda function security-compliance-checker has been executed and has downloaded this weeks compliance data (' + formattedDate + ') for further analysis.'
    else:
        string = 'The lambda function security-compliance-checker has FAILED to execute. Please check the code and try again.'
    slack_data = {'text': string}
    response = requests.post(
    webhook_url, data=json.dumps(slack_data), 
    headers={'Content-Type': 'application/json'}
    )
    if response.status_code != 200:
        raise ValueError(
            'Request to Slack returned an error %s, the response is:\n%s'
            % (response.status_code, response.text)
        )
    
def checkTmpFolder():
    print('Checking /tmp/ folder for CSV proper CSV contents...')
    fileList = os.listdir('/tmp/')
    if len(fileList) == 7:
        print('Number of files in /tmp/: ' + str(len(fileList)))
        return True
    else:
        print('Number of files in /tmp/: ' + str(len(fileList)))
        print('Number of files expected: 7')
        return False

def deleteFiles():
    print('Deleting files in /tmp/...')
    dir = '/tmp/'
    for f in os.listdir(dir):
        os.remove(os.path.join(dir, f))
    directory = os.listdir(dir)
    if len(directory) == 0:
        print('All files deleted...')
    else:
        print('Files were unable to be deleted successfully...')

def write_data_to_tmp(current_date):
    client = boto3.client('securityhub')
    get_total_findings_by_gen_id(client,current_date) # Within each of these functions, create the /tmp file, make the api call and push the data to the csv. 
    get_total_failed_findings_by_gen_id(client,current_date)
    get_total_findings_by_account(client,current_date)
    get_total_failed_findings_by_account(client,current_date)
    get_total_findings_by_resource(client,current_date)
    get_total_failed_findings_by_resource(client,current_date)
    get_total_findings_by_severity(client,current_date)

def get_total_findings_by_gen_id(client,current_date):
    csv_name = '/tmp/total_by_sc.csv'
    print("Generating CSV for total compliance by security control...")
    #insight_arn = os.environ.get('total_control_findings_by_generator_id_arn')
    insight_arns = [os.environ.get('total_control_findings_by_generator_id_a_g_arn'),os.environ.get('total_control_findings_by_generator_id_h_n_arn'),os.environ.get('total_control_findings_by_generator_id_o_u_arn'),os.environ.get('total_control_findings_by_generator_id_v_z_arn')]
    fsub = open(csv_name, 'a', newline='')
    writer = csv.DictWriter(fsub,fieldnames = ['Date', 'Control ID', 'Count', 'Compliance Status'])
    for insight in insight_arns:
        res = client.get_insight_results(InsightArn=insight)
        print(res)
        for attribute in res['InsightResults']['ResultValues']:
            writer.writerow({'Date': current_date, 'Control ID': attribute['GroupByAttributeValue'], 'Count': int(attribute['Count']), 'Compliance Status': 'N/A'})
    fsub.close()

def get_total_failed_findings_by_gen_id(client,current_date):
    csv_name = '/tmp/failed_by_sc.csv'
    print("Generating CSV for total failed rules by security control...")
    #insight_arn = os.environ.get('total_failed_control_findings_by_generator_id_arn')
    insight_arns = [os.environ.get('total_failed_control_findings_by_generator_id_a_f_arn'),os.environ.get('total_failed_control_findings_by_generator_id_g_l_arn'),os.environ.get('total_failed_control_findings_by_generator_id_m_r_arn'),os.environ.get('total_failed_control_findings_by_generator_id_s_x_arn'),os.environ.get('total_failed_control_findings_by_generator_id_y_z_arn')]
    fsub = open(csv_name, 'a', newline='')
    writer = csv.DictWriter(fsub,fieldnames = ['Date', 'Control ID', 'Count', 'Compliance Status'])
    for insight in insight_arns:
        res = client.get_insight_results(InsightArn=insight)
        print(res)
        for attribute in res['InsightResults']['ResultValues']:
            writer.writerow({'Date': current_date, 'Control ID': attribute['GroupByAttributeValue'], 'Count': int(attribute['Count']), 'Compliance Status': 'FAILED'})
    fsub.close()

def get_total_findings_by_account(client,current_date):
    csv_name = '/tmp/total_by_acct.csv'
    print("Generating CSV for total compliance by account id...")
    insight_arn = os.environ.get('total_control_findings_by_account_id_arn')
    insight = client.get_insight_results(InsightArn=insight_arn)
    print(insight)
    fsub = open(csv_name, 'a', newline='')
    writer = csv.DictWriter(fsub,fieldnames = ['Date', 'Account ID', 'Count', 'Compliance Status'])
    for attribute in insight['InsightResults']['ResultValues']:
        writer.writerow({'Date': current_date, 'Account ID': attribute['GroupByAttributeValue'], 'Count': int(attribute['Count']), 'Compliance Status': 'N/A'})
    fsub.close()

def get_total_failed_findings_by_account(client,current_date):
    csv_name = '/tmp/failed_by_acct.csv'
    print("Generating CSV for total failed rules by account id...")
    insight_arn = os.environ.get('total_failed_control_findings_by_account_id_arn')
    insight = client.get_insight_results(InsightArn=insight_arn)
    print(insight)
    fsub = open(csv_name, 'a', newline='')
    writer = csv.DictWriter(fsub,fieldnames = ['Date', 'Account ID', 'Count', 'Compliance Status'])
    for attribute in insight['InsightResults']['ResultValues']:
        writer.writerow({'Date': current_date, 'Account ID': attribute['GroupByAttributeValue'], 'Count': attribute['Count'], 'Compliance Status': 'FAILED'})
    fsub.close()

def get_total_findings_by_resource(client,current_date):
    csv_name = '/tmp/total_by_resource.csv'
    print("Generating CSV for total compliance by resource type...")
    insight_arn = os.environ.get('total_control_findings_by_resource_arn')
    insight = client.get_insight_results(InsightArn=insight_arn)
    print(insight)
    fsub = open(csv_name, 'a', newline='')
    writer = csv.DictWriter(fsub,fieldnames = ['Date', 'Resource Type', 'Count', 'Compliance Status'])
    for attribute in insight['InsightResults']['ResultValues']:
        writer.writerow({'Date': current_date, 'Resource Type': attribute['GroupByAttributeValue'], 'Count': int(attribute['Count']), 'Compliance Status': 'N/A'})
    fsub.close()

def get_total_failed_findings_by_resource(client,current_date):
    csv_name = '/tmp/failed_by_resource.csv'
    print("Generating CSV for total failed rules by resource type...")
    insight_arn = os.environ.get('total_failed_control_findings_by_resource_arn')
    insight = client.get_insight_results(InsightArn=insight_arn)
    print(insight)
    fsub = open(csv_name, 'a', newline='')
    writer = csv.DictWriter(fsub,fieldnames = ['Date', 'Resource Type', 'Count', 'Compliance Status'])
    for attribute in insight['InsightResults']['ResultValues']:
        writer.writerow({'Date': current_date, 'Resource Type': attribute['GroupByAttributeValue'], 'Count': int(attribute['Count']), 'Compliance Status': 'FAILED'})
    fsub.close()

def get_total_findings_by_severity(client,current_date):
    csv_name = '/tmp/total_by_sev.csv'
    print("Generating CSV for total rules by severity...")
    insight_arn = os.environ.get('total_control_findings_by_severity_arn')
    insight = client.get_insight_results(InsightArn=insight_arn)
    print(insight)
    fsub = open(csv_name, 'a', newline='')
    writer = csv.DictWriter(fsub,fieldnames = ['Date', 'Severity Level', 'Count', 'Compliance Status'])
    for attribute in insight['InsightResults']['ResultValues']:
        writer.writerow({'Date': current_date, 'Severity Level': attribute['GroupByAttributeValue'], 'Count': int(attribute['Count']), 'Compliance Status': 'N/A'})
    fsub.close()