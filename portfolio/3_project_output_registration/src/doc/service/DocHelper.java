package doc.service;

public class DocHelper {

	public static final DocService service = ServiceFactory.getService(DocService.class);
	public static final DocHelper manager = new DocHelper();
	
}
