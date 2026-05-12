public with sharing class OdysseusJsonParser {

    /**
     * Resolves a value that may be a plain string or a CDATA wrapper object
     * like {"#cdata-section": "Miami"}.
     */
    public static String resolveCdata(Object val) {
        if (val == null) return null;
        if (val instanceof String) return (String) val;
        if (val instanceof Map<String, Object>) {
            Map<String, Object> m = (Map<String, Object>) val;
            Object cdata = m.get('#cdata-section');
            return cdata != null ? String.valueOf(cdata) : null;
        }
        return String.valueOf(val);
    }

    /**
     * Normalizes a value that could be a single object or an array into a List.
     * Odysseus sometimes sends {"Package": {...}} instead of {"Package": [...]}.
     */
    public static List<Object> toList(Object val) {
        if (val == null) return new List<Object>();
        if (val instanceof List<Object>) return (List<Object>) val;
        return new List<Object>{ val };
    }

    /**
     * Safely reads a nested key path like 'Transaction.Booking.Customer.Email'.
     */
    public static Object getNestedValue(Map<String, Object> root, String path) {
        List<String> keys = path.split('\\.');
        Object current = root;
        for (String key : keys) {
            if (current == null || !(current instanceof Map<String, Object>)) return null;
            current = ((Map<String, Object>) current).get(key);
        }
        return current;
    }

    public static String getNestedString(Map<String, Object> root, String path) {
        Object val = getNestedValue(root, path);
        return val != null ? String.valueOf(val) : null;
    }

    public static Integer getNestedInteger(Map<String, Object> root, String path) {
        String s = getNestedString(root, path);
        if (String.isBlank(s)) return null;
        try { return Integer.valueOf(s.trim()); } catch (Exception e) { return null; }
    }

    public static Decimal getNestedDecimal(Map<String, Object> root, String path) {
        String s = getNestedString(root, path);
        if (String.isBlank(s)) return null;
        try { return Decimal.valueOf(s.trim()); } catch (Exception e) { return null; }
    }

    /**
     * Parses Odysseus dates which come in multiple formats:
     *   dd-MM-yyyy HH:mm:ss   (e.g. "02-01-2025 00:00:00")
     *   dd-MM-yyyy HH:mm      (e.g. "02-01-2025 16:00")
     *   dd-MM-yyyy             (e.g. "13-06-2024")
     *   yyyy-MM-ddTHH:mm:ss   (e.g. "2024-06-06T13:00:10")
     */
    public static Date parseDate(String dateStr) {
        if (String.isBlank(dateStr)) return null;
        dateStr = dateStr.trim();

        try {
            if (dateStr.contains('T')) {
                String datePart = dateStr.substringBefore('T');
                List<String> parts = datePart.split('-');
                if (parts.size() == 3 && parts[0].length() == 4) {
                    return Date.valueOf(datePart);
                }
            }

            String justDate = dateStr.contains(' ') ? dateStr.substringBefore(' ') : dateStr;
            List<String> parts = justDate.split('-');
            if (parts.size() == 3) {
                Integer day = Integer.valueOf(parts[0]);
                Integer month = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(parts[2]);
                if (parts[2].length() <= 2 && year < 100) year += 2000;
                if (year <= 1) return null;
                return Date.newInstance(year, month, day);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'OdysseusJsonParser.parseDate failed for: ' + dateStr);
        }
        return null;
    }

    /**
     * Extracts a price amount from a Prices block by looking for a matching Price ID.
     * Prices can be { Type, Price: [...] } or [ { Type, Price: [...] }, ... ]
     */
    public static Decimal getPriceById(Object pricesObj, String priceId) {
        if (pricesObj == null) return null;

        List<Object> priceArrays = new List<Object>();
        if (pricesObj instanceof Map<String, Object>) {
            Object priceList = ((Map<String, Object>) pricesObj).get('Price');
            if (priceList != null) priceArrays.addAll(toList(priceList));
        } else if (pricesObj instanceof List<Object>) {
            for (Object item : (List<Object>) pricesObj) {
                if (item instanceof Map<String, Object>) {
                    Object priceList = ((Map<String, Object>) item).get('Price');
                    if (priceList != null) priceArrays.addAll(toList(priceList));
                }
            }
        }

        for (Object priceItem : priceArrays) {
            if (!(priceItem instanceof Map<String, Object>)) continue;
            Map<String, Object> p = (Map<String, Object>) priceItem;
            if (String.valueOf(p.get('ID')) == priceId) {
                String amt = String.valueOf(p.get('Amount'));
                if (String.isNotBlank(amt)) {
                    try { return Decimal.valueOf(amt.trim()); } catch (Exception e) { /* skip */ }
                }
            }
        }
        return null;
    }

    /**
     * Extracts the first cruise-type package from the Packages structure.
     * Handles both array and object wrapper forms.
     */
    public static Map<String, Object> findCruisePackage(Object packagesObj) {
        if (packagesObj == null) return null;

        List<Object> packageGroups = toList(packagesObj);
        for (Object grp : packageGroups) {
            List<Object> packages;
            if (grp instanceof Map<String, Object>) {
                Object nested = ((Map<String, Object>) grp).get('Package');
                if (nested != null) {
                    packages = toList(nested);
                } else {
                    String pType = (String) ((Map<String, Object>) grp).get('Type');
                    if (pType != null && pType.equalsIgnoreCase('Cruise')) {
                        return (Map<String, Object>) grp;
                    }
                    packages = new List<Object>{ grp };
                }
            } else {
                continue;
            }

            for (Object pkg : packages) {
                if (!(pkg instanceof Map<String, Object>)) continue;
                Map<String, Object> pkgMap = (Map<String, Object>) pkg;
                String pType = String.valueOf(pkgMap.get('Type'));
                if (pType != null && pType.equalsIgnoreCase('Cruise')) {
                    return pkgMap;
                }
            }
        }
        return null;
    }

    /**
     * Collects all non-cruise packages (ActivityAddOn, Transfer, Hotel, Activity).
     */
    public static List<Map<String, Object>> findNonCruisePackages(Object packagesObj) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        if (packagesObj == null) return results;

        List<Object> packageGroups = toList(packagesObj);
        for (Object grp : packageGroups) {
            List<Object> packages;
            if (grp instanceof Map<String, Object>) {
                Object nested = ((Map<String, Object>) grp).get('Package');
                if (nested != null) {
                    packages = toList(nested);
                } else {
                    packages = new List<Object>{ grp };
                }
            } else {
                continue;
            }

            for (Object pkg : packages) {
                if (!(pkg instanceof Map<String, Object>)) continue;
                Map<String, Object> pkgMap = (Map<String, Object>) pkg;
                String pType = String.valueOf(pkgMap.get('Type'));
                if (pType != null && !pType.equalsIgnoreCase('Cruise')) {
                    results.add(pkgMap);
                }
            }
        }
        return results;
    }

    /**
     * Maps Odysseus package type to Add_On__c.Add_On_Type__c picklist value.
     */
    public static String mapAddOnType(String odysseusType) {
        if (String.isBlank(odysseusType)) return 'Other';
        String t = odysseusType.toLowerCase();
        if (t.contains('hotel')) return 'Other';
        if (t.contains('air')) return 'Other';
        if (t.contains('transfer')) return 'Transfer';
        if (t.contains('activity') || t.contains('addon')) return 'Shore Excursion';
        return 'Other';
    }

    /**
     * Maps Odysseus booking status to Salesforce Status__c picklist.
     */
    public static String mapBookingStatus(String odysseusStatus) {
        if (String.isBlank(odysseusStatus)) return 'Quote';
        String s = odysseusStatus.toLowerCase();
        if (s.contains('confirmed')) return 'Booking';
        if (s.contains('cancelled') || s.contains('canceled')) return 'Cancelled';
        if (s.contains('completed')) return 'Completed';
        return 'Quote';
    }
}
