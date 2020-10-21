// =============================================================================================
//  Object: QueryUtils
//  Company: Salesforce
//  Purpose: Query Builder/Factory to create Query Dynamically.
// =============================================================================================
public class QueryUtils
{
    public Schema.SObjectType table {get; private set;}
    private Boolean enforceFLS;
    private SelectClause selectClause;
    private FromClause fromClause;
    private String whereClause;

    // ============================================================================
    // Methods
    // ============================================================================
    /**
     * @name Constructor
     * @description constructor to create an instance of QueryUtils for given SObject
     * @param Schema.SObjectType
     * @return NA
     * @exception
     * @author Lopa
     * @created 2018-06-11
     * @remark
     * @change
     */
    public QueryUtils(Schema.SObjectType table)
    {
        this.table = table;
        enforceFLS = false;
        selectClause = new SelectClause(table, enforceFLS);
        fromClause = new FromClause(table.getDescribe().getName());
    }

    /**
      * Returns SELECT clause.
      */
    public SelectClause getSelectClause()
    {
        return selectClause;
    }

    /**
     * Generates SOQL string.
     */
    public String buildSOQL()
    {
        String soql = selectClause.buildSOQL();
        soql += (' ' + fromClause.buildSOQL());
        if(whereClause!=null){
            soql +=(' ' + whereClause);
        }
        String rt = soql.trim();
        return rt;
    }

    /**
      * Joins specified array of Expression values using specified separator.
      */
    private static String join(List<Expression> values, String separator)
    {
        // Handle null values
        if ((values == null) || (values.size() == 0))
        {
            return '';
        }
        if (separator == null)
        {
            separator = '';
        }

        String result = '';
        for (Expression value : values)
        {
            if (value == null)
            {
                continue;
            }
            String fragment = value.buildSOQL();
            if (value instanceof QueryUtils)
            {
                // This is a sub-qury. Enclose in paranthesis
                fragment = '(' + fragment + ')';
            }
            result += (fragment + separator);
        }
        // Chop off trailing separator
        result = result.substring(0,result.length() - separator.length());
        return result;
    }

    /**
     * Contract for a class capabale of generating SOQL expressions.
     */
    public interface Expression
    {
        /**
         * Generates SOQL fragment for this expression.
         */
        String buildSOQL();
    }

    /**
     * Expression implementation that supports nested expressions.
     */
    public abstract class ComplexExpression implements Expression
    {
        private List<Expression> expressions = new List<Expression>();

        /**
         * Adds specified expression to the list of expressions maintained by this clause.
         */
        public ComplexExpression addExpression(Expression expr)
        {
            if (expr != null)
            {
                expressions.add(expr);
            }
            return this;
        }

        /**
         * Returns the list of expressions accumulated by this clause.
         */
        public List<Expression> getExpressions()
        {
            return expressions;
        }
    }

    /**
     * Simple Expression implementation that constructs a field path.
     */
    public class FieldExpression implements Expression
    {
        private String field;
        private String relationship;
        private Boolean translatable;

        /**
         * Default constructor.
         */
        public FieldExpression(String relationship, String field, Boolean translatable)
        {
            this.field = field;
            this.relationship = relationship;
            this.translatable = translatable;
        }

        public FieldExpression(String field, Boolean translatable)
        {
            //this.field = field;
            //this.relationship = relationship;
            this(null, field, translatable);
        }

        /**
         * Generates SOQL fragment.
         */
        public String buildSOQL()
        {
            String fieldValue = '';
            if (relationship != null)
            {
                fieldValue = relationship + '.' + field;
            }
            else
            {
                fieldValue = field;
            }

            if ( translatable )
            {
                fieldValue = 'toLabel(' + fieldValue + ')';
            }

            return fieldValue;
        }
    }

    /**
     * Expression implementation that knows how to build SELECT clause.
     */
    public class SelectClause extends ComplexExpression
    {
        private Set<String> existing = new Set<String>();
        private Schema.SObjectType table;
        private Boolean enforceFLS;

        public SelectClause(Schema.SObjectType table, Boolean enforceFLS)
        {
            super();
            this.table = table;
            this.enforceFLS = enforceFLS;
        }

        /**
         * @name addField
         * @description method to add a field to SelectClause
         * @param SObjectField
         * @return SelectClause
         * @exception InvalidFieldException
         * @exception FLSException
         * @author Lopa
         * @created 2018-06-11
         * @remark
         * @change
         *
         */
        public SelectClause addField(SObjectField field)
        {
            Schema.DescribeFieldResult describeFieldResultInstance = field.getDescribe();
            if (describeFieldResultInstance.isAccessible())
            {
                addField(describeFieldResultInstance.getName(), toTranslate(field));
                existing.add(describeFieldResultInstance.getName().toLowerCase());
            }
            return this;
        }

        /**
          * Convenience method to add several fields expressed as Schema.SObjectField
          */
        public SelectClause addFields(Schema.SObjectField[] fields)
        {
            for (Schema.SObjectField field : fields)
            {
                addField(field);
            }
            return this;
        }

        public SelectClause addField(String field, Boolean translatable)
        {
            if (!existing.contains(field.toLowerCase())) {
                addExpression(new FieldExpression(field, translatable));
                existing.add(field.toLowerCase());
            }
            return this;
        }

        /**
         * Generates SOQL for the WHERE clause.
         */
        public String buildSOQL()
        {
            return 'SELECT ' + QueryUtils.join(getExpressions(), ',');
        }

        /*
        * To test if field is translatable in the SOQL
        */
        public Boolean toTranslate(Schema.SObjectField field )
        {
            Set<Schema.DisplayType> translatableTypeList = new Set<Schema.DisplayType>
            {
                    Schema.DisplayType.MultiPicklist,
                    Schema.DisplayType.Picklist
            };

            return translatableTypeList.contains(field.getDescribe().getType());
        }
    }

    /**
     * Expression implementation that knows how to build FROM clause.
     */
    public class FromClause implements Expression
    {
        private String objectName;

        /**
         * Default constructor;
         */
        public FromClause(String objectName)
        {
            this.objectName = objectName;
        }

        /**
         * Generates SOQL for the WHERE clause.
         */
        public String buildSOQL()
        {
            return 'FROM ' + objectName;
        }
    }
    public void setWhereClause(String whereClause){
        this.whereClause = whereClause;
    }
}