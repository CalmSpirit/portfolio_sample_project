package project.controller;

import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import common.util.CommonUtil;
import project.service.ProjectHelper;

@Controller
@RequestMapping("/project")
public class ProjectController {
	
	
	@RequestMapping("/createProject")
	public ModelAndView createProject(@RequestParam Map<String, Object> reqMap) {
		ModelAndView model = new ModelAndView();
		
		model.setViewName("default:/project/createProject");
		
		return model;
	}
	
	@ResponseBody
	@RequestMapping("/createProjectAction")
	public Map<String, Object> createProjectAction(HttpServletRequest request, HttpServletResponse response) {

		Map<String, Object> map = new HashMap<String, Object>();

		try {

			ProjectHelper.service.createProjectAction(request, response);

			map.put("result", true);
			map.put("msg", "등록이 완료되었습니다.");
			map.put("redirectUrl", CommonUtil.getURLString("/project/searchProject"));

		} catch (Exception e) {
			map.put("result", false);
			map.put("msg", "ERROR = " + e.getLocalizedMessage());
			e.printStackTrace();
		}

		return map;
	}
	
}
