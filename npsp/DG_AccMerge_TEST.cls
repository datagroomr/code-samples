@isTest
public class DG_AccMerge_TEST {
  public static List<Account> listAccT;
  public static List<Contact> listConT;
  public static String closedWonStage;

  private interface RecordTypeInfo {
    Schema.RecordTypeInfo getRecordTypeInfo();
    String getName();
    Id getRecordTypeId();
    Boolean isAvailable();
    Boolean isDefaultRecordTypeMapping();
    Boolean isMaster();
  }

  private class RecordTypeInfoWrapper implements RecordTypeInfo {
    private Schema.RecordTypeInfo rti;
    public RecordTypeInfoWrapper(Schema.RecordTypeInfo rti) {
      this.rti = rti;
    }
    public Schema.RecordTypeInfo getRecordTypeInfo() {
      return this.rti;
    }
    public String getName() {
      return rti.getName();
    }
    public Id getRecordTypeId() {
      return rti.getRecordTypeId();
    }
    public Boolean isAvailable() {
      return rti.isAvailable();
    }
    public Boolean isDefaultRecordTypeMapping() {
      return rti.isDefaultRecordTypeMapping();
    }
    public Boolean isMaster() {
      return rti.isMaster();
    }
  }

  private class UnavailableRecordTypeInfo implements RecordTypeInfo {
    public Schema.RecordTypeInfo getRecordTypeInfo() {
      return null;
    }
    public String getName() {
      return '';
    }
    public Id getRecordTypeId() {
      return null;
    }
    public Boolean isAvailable() {
      return false;
    }
    public Boolean isDefaultRecordTypeMapping() {
      return false;
    }
    public Boolean isMaster() {
      return false;
    }
  }

  public static String getUniqueString() {
    return String.valueOf(Math.abs(getRandomLong));
  }

  private static Long getRandomLong {
    get {
      if (getRandomLong == null) {
          getRandomLong = Crypto.getRandomLong();
      } else {
          getRandomLong += 1;
      }
      return getRandomLong;
    } set;
  }

  public static List<Contact> createAccountContactTestData(String accType, Integer cAcc, Integer cCon, Integer iUnique) {
    listConT = createMultipleTestContacts(cAcc * cCon);
    listAccT = createMultipleTestAccounts(cAcc, accType);
    insert listAccT;
    for (Integer i = 0; i < cAcc; i++) {
      for (Integer j = 0; j < cCon; j++) {
        Integer iCon = (i * cCon) + j;
        String unique = getUniqueString();
        Contact con = listConT[iCon];
        con.FirstName = 'TestFirstName' + iUnique + iCon;
        con.LastName = 'TestLastName' + iUnique + iCon + unique;
        con.AccountId = listAccT[i].Id;
        con.MailingStreet = 'Street' + iUnique + iCon + unique;
        con.MailingCity = 'City' + iUnique + iCon;
      }
    }
    insert listConT;
    return listConT;
  }

  public static List<Account> createMultipleTestAccounts (Integer n, String strType) {
      List<Account> accountsToAdd = new List<Account> ();
      for (Integer i=0; i<n; i++) {
        Account newAcct = new Account (
          Name = 'Test Account ' + getUniqueString(),
          npe01__SYSTEM_AccountType__c = strType
        );
        if (strType != null) {
          newAcct.npe01__SYSTEMIsIndividual__c = true;
          if (strType == 'Bucket Individual') {
              newAcct.Name = 'Individual';
          }
        }
        accountsToAdd.add (newAcct);
      }
      return accountsToAdd;
  }

  public static Contact getContact() {
    return new Contact (
      FirstName = 'CONTACT_FIRSTNAME_FOR_TESTS' + getUniqueString(),
      LastName = 'CONTACT_LASTNAME_FOR_TESTS' + getUniqueString(),
      npe01__Private__c = false,
      npe01__WorkEmail__c = 'junk@test.net',
      npe01__Preferred_Email__c = 'Work',
      npe01__WorkPhone__c = '206-777-8888',
      npe01__PreferredPhone__c = 'Work',
      OtherCity = 'Seattle'
    );
  }

  public static List<Contact> createMultipleTestContacts(Integer n) {
    List<Contact> contactsToAdd = new List<Contact> ();
    for (Integer i=0; i<n; i++) {
      Contact newCon = getContact();
      contactsToAdd.add (newCon);
    }
    return contactsToAdd;
  }

  private static Map<String, Schema.RecordTypeInfo> getObjectRecordTypeInfos(sObjectType objectType, Boolean activeOnly, Boolean assignedOnly) {
    Map<String, Schema.RecordTypeInfo> objectRecordTypeInfoToFilter = objectType.getDescribe().getRecordTypeInfosByName();
    Map<String, Schema.RecordTypeInfo> objectRecordTypeInfos = new Map<String, Schema.RecordTypeInfo>(objectRecordTypeInfoToFilter);
    for (String recTypeName : objectRecordTypeInfoToFilter.keySet()) {
      Schema.RecordTypeInfo rt = objectRecordTypeInfoToFilter.get(recTypeName);
      if (activeOnly && !rt.isActive()) {
        objectRecordTypeInfos.remove(recTypeName);
        continue;
      }
      if (assignedOnly && !rt.isAvailable()) {
        objectRecordTypeInfos.remove(recTypeName);
      }
    }
    return objectRecordTypeInfos;
  }

  private static Map<String, Schema.RecordTypeInfo> getActiveRecordTypes(sObjectType objectType) {
    return getObjectRecordTypeInfos(objectType, true, false);
  }

  private static RecordTypeInfo getRecordTypeInfo(sObjectType objectType, String recordTypeName) {
    Map<String, Schema.RecordTypeInfo> recordTypeInfos = getActiveRecordTypes(objectType);
    if (recordTypeInfos.containsKey(recordTypeName)) {
      return new RecordTypeInfoWrapper(recordTypeInfos.get(recordTypeName));
    } else {
      return new UnavailableRecordTypeInfo();
    }
  }

  public static Id getRecordTypeId(sObjectType objectType, String recordTypeName) {
    return getRecordTypeInfo(objectType, recordTypeName).getRecordTypeId();
  }

  public static List<Opportunity> oppsForContactListByRecTypeId(List<Contact> contacts, Id campaignId, String stage, Date closeDate, Double amt, Id rtId, String oppType) {
    List<Opportunity> oppsToAdd = new List<Opportunity> ();
    for ( Contact thisCon : contacts ) {
        Opportunity newOpp = new Opportunity (
          Name = 'Test Opp ' + thisCon.FirstName + thisCon.LastName,
          Amount = amt,
          CloseDate = closeDate,
          StageName = stage,
          CampaignId = campaignId,
          Type = oppType
        );
        if (rtId != null) {
          newOpp.put('RecordTypeId', rtId);
        }
        oppsToAdd.add (newOpp);
    }
    return oppsToAdd;
  }

  public static List<Opportunity> oppsForContactList(List<Contact> contacts, Id campaignId, String stage, Date closeDate, Double amt, String recordTypeName, String oppType ) {
    Id rtId = getRecordTypeId (Opportunity.SObjectType, recordTypeName);
    return oppsForContactListByRecTypeId(contacts, campaignId, stage, closeDate, amt, rtId, oppType);
  }

  public static String getClosedWonStage() {
    if (closedWonStage == null) {
      List<OpportunityStage> closedWonStages = [
        SELECT MasterLabel
        FROM OpportunityStage
        WHERE IsActive = TRUE
        AND IsWon = TRUE
      ];
      if (closedWonStages.size()>0) {
        closedWonStage = closedWonStages[0].MasterLabel;
      } else {
        closedWonStage = '';
      }
    }
    return closedWonStage;
  }
        
  static testMethod void testMergeTwoHHAccounts() {
    integer cHH;
    integer cCon;
    // create our source account and contacts
    DG_AccMerge_TEST.createAccountContactTestData('Household Account', 2, 2, 1);        
    // this creates some test opps
    list<Opportunity> listOpp = DG_AccMerge_TEST.OppsForContactList(DG_AccMerge_TEST.listConT, null, 
    DG_AccMerge_TEST.getclosedWonStage(), System.Today(), 100, null, null);
    insert listOpp;        
    // decide who wins (and remember who was primary contact)
    Account accWinner = [select Id, Name, npe01__One2OneContact__c from Account where Id = :DG_AccMerge_TEST.listAccT[1].Id];
    Account accLoser = DG_AccMerge_TEST.listAccT[0];
    // merge the Accounts
    Test.startTest();
    merge accWinner accLoser;
    // to flush our future calls that fix related data up!        
    Test.stopTest();
    // reload our contacts and accounts
    list<Account> listAcc = new list<Account>([select Id, Name, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
        npo02__NumberOfClosedOpps__c, npe01__One2OneContact__c, 
        BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
        from Account order by Id]);
    list<Contact> listCon = [select Id, Firstname, AccountId, 
        MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry 
        from Contact order by Id];
        
    // verify the accounts and contacts
    System.assertEquals(1, listAcc.size());
    System.assertEquals(accWinner.Id, listAcc[0].Id);
    System.assertEquals(4, listCon.size());
                
    // verify the contacts belong to correct account.
    System.assertEquals(listCon[0].AccountId, listAcc[0].Id);
    System.assertEquals(listCon[1].AccountId, listAcc[0].Id);
    System.assertEquals(listCon[2].AccountId, listAcc[0].Id);
    System.assertEquals(listCon[3].AccountId, listAcc[0].Id);
    
    // verify that primary contact did not change
    System.assertEquals(accWinner.npe01__One2OneContact__c, listAcc[0].npe01__One2OneContact__c);        
        
    // verify the account's greetings are updated (lastnames are the same so the account name won't change!)
    System.assertEquals(true, listAcc[0].npo02__Formal_Greeting__c.contains(listCon[0].Firstname));        
    System.assertEquals(true, listAcc[0].npo02__Formal_Greeting__c.contains(listCon[1].Firstname));        
    System.assertEquals(true, listAcc[0].npo02__Formal_Greeting__c.contains(listCon[2].Firstname));        
    System.assertEquals(true, listAcc[0].npo02__Formal_Greeting__c.contains(listCon[3].Firstname));        
  }
}
