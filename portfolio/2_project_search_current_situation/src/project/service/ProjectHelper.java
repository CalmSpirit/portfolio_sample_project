package project.service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import common.util.StringUtil;
import common.web.PageQueryBroker;
import project.EProject;
import project.bean.ProjectCurrentSituationData;

public class ProjectHelper {

	public static final ProjectService service = ServiceFactory.getService(ProjectService.class);
	public static final ProjectHelper manager = new ProjectHelper();

	public Map<String, Object> getProjectCurrentSituationScrollList(Map<String, Object> reqMap) throws Exception {

		Map<String, Object> map = new HashMap<String, Object>();

		List<ProjectCurrentSituationData> list = new ArrayList<ProjectCurrentSituationData>();

		int page = (Integer) reqMap.get("page");
		int rows = (Integer) reqMap.get("rows");
		String sessionId = StringUtil.checkNull((String) reqMap.get("sessionId"));

		PagingQueryResult result = null;

		if (sessionId.length() > 0) {
			result = PagingSessionHelper.fetchPagingSession((page - 1) * rows, rows, Long.valueOf(sessionId));
		} else {
			
			if(reqMap.get("sortValue") == null || "".equals(reqMap.get("sortValue"))) {
				reqMap.put("sortCheck", true);
				reqMap.put("sortValue", "name");
			}
			
			QuerySpec query = getProjectListQuery(reqMap);

			result = PageQueryBroker.openPagingSession((page - 1) * rows, rows, query, true);
		}

		int totalSize = result.getTotalSize();

		while (result.hasMoreElements()) {
			Object[] obj = (Object[]) result.nextElement();
			EProject project = (EProject) obj[0];

			list.add(new ProjectCurrentSituationData(project));
		}

		map.put("list", list);
		map.put("totalSize", totalSize);
		map.put("sessionId", result.getSessionId() == 0 ? "" : result.getSessionId());

		return map;
	}
	
}
