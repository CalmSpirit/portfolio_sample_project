package doc.service;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@RemoteInterface
public interface DocService {
	
	public abstract void createDocMultiAction(HttpServletRequest request, HttpServletResponse response) throws Exception;

}
