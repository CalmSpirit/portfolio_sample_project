package project.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import project.service.ProjectHelper;

@Controller
@RequestMapping("/project")
public class ProjectController {
	
	
	/**
	 * @methodName : projectCurrentSituation
	 * @author : hckim
	 * @date : 2021.11.15
	 * @return : ModelAndView
	 * @description : 프로젝트 현황
	 */
	@RequestMapping("/projectCurrentSituation")
	public ModelAndView projectCurrentSituation(@RequestParam Map<String, Object> reqMap) {
		ModelAndView model = new ModelAndView();
		
		model.setViewName("default:/project/projectCurrentSituation");
		
		return model;
	}
	
	

	/**
	 * @methodName : projectCurrentSituationScrollAction
	 * @author : hckim
	 * @date : 2021.11.15
	 * @return : Map<String,Object>
	 * @description : 
	 */
	@ResponseBody
	@RequestMapping("/projectCurrentSituationScrollAction")
	public Map<String, Object> projectCurrentSituationScrollAction(@RequestBody Map<String, Object> reqMap) {
		Map<String, Object> map = new HashMap<String, Object>();
		
		try {
			map = ProjectHelper.manager.getProjectCurrentSituationScrollList(reqMap);
			map.put("result", true);
			
		} catch (Exception e) {
			e.printStackTrace();
			map.put("result", false);
			map.put("msg", "ERROR = " + e.getLocalizedMessage());
		}
		
		return map;
	}
		
	
}
