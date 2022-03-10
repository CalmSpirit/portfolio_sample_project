package doc.service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import common.util.StringUtil;
import common.web.PageQueryBroker;
import doc.beans.DocData;


public class DocHelper {

	public static final DocService service = ServiceFactory.getService(DocService.class);
	public static final DocHelper_asdf manager = new DocHelper_asdf();

	public Map<String, Object> getDocScrollList(Map<String, Object> reqMap) throws Exception {

		Map<String, Object> map = new HashMap<>();

		List<DocData> list = new ArrayList<>();

		int page = (Integer) reqMap.get("page");
		int rows = (Integer) reqMap.get("rows");
		String sessionId = StringUtil.checkNull((String) reqMap.get("sessionId"));

		PagingQueryResult result = null;

		if (sessionId.length() > 0) {
			result = PagingSessionHelper.fetchPagingSession((page - 1) * rows, rows, Long.valueOf(sessionId));
		} else {
			QuerySpec query = getDocListQuery(reqMap);

			result = PageQueryBroker.openPagingSession((page - 1) * rows, rows, query, true);
		}

		int totalSize = result.getTotalSize();

		while (result.hasMoreElements()) {

			Object[] obj = (Object[]) result.nextElement();
			WTDocument doc = (WTDocument) obj[0];
			DocData data = new DocData(doc, false);

			list.add(data);
		}

		map.put("list", list);
		map.put("totalSize", totalSize);
		map.put("sessionId", result.getSessionId() == 0 ? "" : result.getSessionId());

		return map;
	}
	
}
