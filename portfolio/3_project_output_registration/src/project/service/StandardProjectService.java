package project.service;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import doc.service.DocHelper;


public class StandardProjectService implements ProjectService {
	
	@Override
	public void createOutputDocumentAction(HttpServletRequest request, HttpServletResponse response) throws Exception{
		
		DocHelper.service.createDocMultiAction(request, response);
	}
	
}
