package project.service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import approval.service.ApprovalHelper;
import approval.util.ApprovalUtil;
import common.content.FileRequest;
import common.log4j.ObjectLogger;
import common.util.CommonUtil;
import common.util.StringUtil;
import doc.service.DocHelper;
import doc.util.DocUtil;
import project.EOutput;
import project.EProject;
import project.ProjectToPartLink;
import project.RoleUserLink;
import project.jira.JiraIssueTaskLink;
import project.util.ProjectUtil;

public class StandardProjectService implements ProjectService {


	@Override
	public EProject createProjectAction(HttpServletRequest request, HttpServletResponse response) throws Exception {


		EProject project = null;
		Transaction trx = null;

		try {
			trx = new Transaction();
			trx.start();

			FileRequest fileReq = new FileRequest(request);
			ObjectLogger.debug(fileReq, "FILEREQ");


			// 참조 문서
			List<Map<String, Object>> refDocList = DocUtil.toRefDocList(fileReq, false);
			ObjectLogger.debug(refDocList, "refDocList");

			// 관련 품목
			String[] relPartOids = fileReq.getParameterValues("add_part_oid");
			ObjectLogger.debug(relPartOids, "relPartOids");

			// Gate
			List<Map<String, Object>> gateList = ProjectUtil.toJiraGateList(fileReq);
			ObjectLogger.debug(gateList, "gateList");

			// 산출물
			List<Map<String, Object>> outputList = ProjectUtil.toOutputList(fileReq);
			ObjectLogger.debug(outputList, "outputList");

			// 구성원
			List<Map<String, Object>> memberList = ProjectUtil.toProjectMemberList(fileReq);
			ObjectLogger.debug(memberList, "memberList");

			///////////////////////////////////////////////////////////////////
			Map<String, Object> projectHash = ProjectUtil.toProjectHash(fileReq);

			// 프로젝트
			project = saveProject(projectHash);
			ObjectLogger.debug(project, "project");

			// 참조 문서
			List<WTDocument> createdRefDocs = new ArrayList<WTDocument>();
			for (Map<String, Object> refDocHash : refDocList) {
				WTDocument refDoc = DocHelper.service.createReferenceDocumentAction(project, refDocHash);
				createdRefDocs.add(refDoc);
			}

			// 관련 품목
			List<ProjectToPartLink> relPartLinkList = new ArrayList<ProjectToPartLink>();
			if (relPartOids != null) {
				for (String partOid : relPartOids) {
					WTPart part = (WTPart) CommonUtil.getObject(partOid);
					if (part != null) {
						WTPartMaster partMaster = part.getMaster();

						ProjectToPartLink createdLink = saveProjectToPartLink(project, partMaster);
						relPartLinkList.add(createdLink);
					}
				}
			}

			// 테스크(Gate)
			List<JiraIssueTaskLink> links = saveGateTask(project, gateList);

			// 산출물
			List<EOutput> createdOutputList = saveOutput(project, outputList);

			// ROLE
			List<RoleUserLink> createdRoleUserLink = saveMember(project, memberList);
			
			// 결재 등록(기안)
			ApprovalHelper.service.registApproval(project, new ArrayList<Map<String,Object>>(), ApprovalUtil.STATE_MASTER_TEMP_STORAGE, null, "");

			trx.commit();
			trx = null;
		} catch (Exception e) {

			e.printStackTrace();
			throw e;

		} finally {
			if (trx != null) {
				trx.rollback();
				trx = null;
			}
		}

		return project;
	}
	
}
