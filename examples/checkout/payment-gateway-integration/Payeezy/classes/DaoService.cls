/**
 * Class that contains all the methods that interacts with the database
 */ 
public class DaoService {
    /**
     * Method to get the sobject record using the id
     */
	public static SObject getSobjectById(String objectId,List<String> listOfFields,Schema.SObjectType objectType){
        //Basic query structure to get record using id
        String selectSobjectById = 'SELECT {0} FROM {1} WHERE Id = {2}';
        // Add required fields
        String queryFields = '';
        for(String field : listOfFields){
            queryFields = queryFields + field + ', ';
        }
		queryFields = queryFields.substring(0, queryFields.length()-2);
        //Name of the object
        String objectName = objectType.getDescribe().getName();
        //Id of the object
        objectId = '\''+objectId+'\'';
        String queryString = String.format(selectSobjectById,new List<String>{queryFields,objectName,objectId});
        //Call to the database to fetch the record
        SObject objectRecord = Database.query(queryString)[0];
        return objectRecord;
    }
}