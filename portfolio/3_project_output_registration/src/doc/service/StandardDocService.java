
package doc.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import approval.service.ApprovalHelper;
import approval.service.MultiApprovalHelper;
import approval.util.ApprovalUtil;
import common.content.FileRequest;
import common.log4j.ObjectLogger;
import common.util.CommonUtil;
import common.util.StringUtil;
import doc.DocKey;
import doc.util.DocUtil;
import project.EOutput;
import project.ProjectKey;
import project.service.ProjectHelper;
import project.util.ProjectUtil;


public class StandardDocService implements DocService {
	

	/**
	 * @methodName : createDocMultiAction
	 * @author : hckim
	 * @date : 2021.09.24
	 * @param request
	 * @param response
	 * @throws Exception
	 * @description :
	 */
	@Override
	public void createDocMultiAction(HttpServletRequest request, HttpServletResponse response) throws Exception {

		FileRequest fileReq = null;

		Transaction trx = null;
		try {
			trx = new Transaction();
			trx.start();

			fileReq = new FileRequest(request);
			ObjectLogger.debug(fileReq, "FILEREQ");
			
			String total = "";
			String module = StringUtil.checkNull(fileReq.getParameter("requestModule"));
			// String container = fileReq.getParameter("container");

			// 본 문서
			List<Map<String, Object>> docList = null;
			if(module.equals(DocKey.MODULE_DOC.getKey())) {
				total = StringUtil.checkReplaceStr(fileReq.getParameter("totalSize"), "0");
				//일반 문서 멀티등록
				docList = DocUtil.toDocList(fileReq);
			}else if(module.equals(ProjectKey.MODULE_OUTPUT.getKey())){
				total = StringUtil.checkReplaceStr(fileReq.getParameter("output_totalSize"), "0");
				//산출물 멀티등록
				docList = ProjectUtil.toOutputList(fileReq);
			}
			if(docList == null || docList.size() <= 0) {
				throw new Exception("비정상적인 접근입니다.");
			}
			
			// 참조문서
			List<Map<String, Object>> refDocList = DocUtil.toRefDocList(fileReq);
			// 관련 부품
			List<Map<String, Object>> relPartList = DocUtil.toRelPartList(fileReq);

			ObjectLogger.debug(docList, "docList");
			ObjectLogger.debug(refDocList, "refDocList");
			ObjectLogger.debug(relPartList, "relPartList");

			List<Persistable> createdDoc = new ArrayList<Persistable>();

			for (int i = 0; i < Integer.parseInt(total); i++) {

				
				Map<String, Object> docHash = docList.get(i);
				
				// 프로젝트, 설계변경의 참조 문서 인 경우(문서 등록 창에서)
				boolean isEchangeProjectDoc = StringUtil.checkNull((String)docHash.get("eChangeProjectOid")).length() > 0 ? true : false; 
				if(isEchangeProjectDoc) {
					WTDocument eChangeProjectRefDoc = createEchangeProjectRefDoc(docHash);
					if(eChangeProjectRefDoc != null) {
						createdDoc.add(eChangeProjectRefDoc);
					}
					continue;
				}
				
				
				// 본 문서
				WTDocument newDoc = DocHelper.service.createDocAction(docHash);

				//AUIGrid _$uid
				String rowID = (String) docList.get(i).get("row_id");

				// 참조 문서
				if (refDocList.size() > 0) {
					List<WTDocument> refList = createReferenceDocument((Persistable) newDoc, rowID, refDocList);
					ObjectLogger.debug(refList, "createDocuMultiAction refList");
				}

				// 관련 품목
				if (relPartList.size() > 0) {
					List<WTPartDescribeLink> partlink = createRelatedPartLink(newDoc, rowID, relPartList);
					ObjectLogger.debug(partlink, "createDocMultiAction partlink");
				}
				
				// 산출물 링크
				if(module.equals(ProjectKey.MODULE_OUTPUT.getKey())){
					
					String outputOid = (String)docHash.get("output_oid");
					String jiraIssueId = (String)docHash.get("output_jiraIssueId");
					
					//산출물 정의의 산출물 등록
					if(outputOid.length() > 0) {
						EOutput output = (EOutput)CommonUtil.getObject(outputOid);
						output = ProjectHelper.service.registOutputDocument(output, newDoc);
						
						//Output에 Jira Issue Id 등록
						output.setJiraIssueId(jiraIssueId);
						PersistenceHelper.manager.modify(output);
					}
					
				}
				
				createdDoc.add(newDoc);
			}

			// 결재선 등록(단일 : 단일 건에 대한 결재 || 멀티 : 일괄 결재)
			List<Map<String, Object>> approvalList = ApprovalUtil.toApprovalList(fileReq);
			ObjectLogger.debug(approvalList, "approvalList");

			if (1 < Integer.parseInt(total)) {

				Map<String, Object> multiAppHash = ApprovalUtil.toMultiApprovalHash(createdDoc, approvalList);
				MultiApprovalHelper.service.createMultiApprovalAction(multiAppHash, false);

			} else if (1 == Integer.parseInt(total)) {

				String appState = ApprovalUtil.checkAppState(approvalList);
				ApprovalHelper.service.registApproval(createdDoc.get(0), approvalList, appState, null, "");

			}

			trx.commit();
			trx = null;

		} catch (Exception e) {
			throw e;
		} finally {
			if (trx != null) {
				trx.rollback();
				trx = null;
			}
		}

	}
}