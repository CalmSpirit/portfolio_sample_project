package project.service;

import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import common.code.NumberCode;
import common.content.FileRequest;
import project.EOutput;
import project.EProject;
import project.ETask;
import project.ETaskNode;
import project.OutputTypeStep;
import project.ProjectRole;
import project.ProjectToPartLink;
import project.RoleUserLink;
import project.ScheduleNode;
import project.jira.JiraIssueTaskLink;

@RemoteInterface
public interface ProjectService {
	
	
	public abstract EProject createProjectAction(HttpServletRequest request, HttpServletResponse response) throws Exception;

}
