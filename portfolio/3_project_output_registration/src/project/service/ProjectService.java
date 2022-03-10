package project.service;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@RemoteInterface
public interface ProjectService {
	
	public abstract void createOutputDocumentAction(HttpServletRequest request, HttpServletResponse response) throws Exception;

}
