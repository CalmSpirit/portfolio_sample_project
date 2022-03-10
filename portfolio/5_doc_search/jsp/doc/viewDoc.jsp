<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!-- 각 화면 개발시 Tag 복사해서 붙여넣고 사용할것 -->    
<%@ taglib prefix="c"		uri="http://java.sun.com/jsp/jstl/core"			%>
<%@ taglib prefix="tl" 	uri="/WEB-INF/tlds/tl-functions.tld"%>
<script>
$(document).ready(function(){
	
	loadIncludePage();
	
});

function modifyDoc() {
	var url = getURLString("/doc/modifyDoc") + "?oid=${doc.oid}";
	
	location.href = url;
}

function deleteDoc() {
	openConfirm("${tl:getMessage('삭제하시겠습니까?')}", function(){
		
		var param = new Object();
		
		param.oid = "${doc.oid}";
		
		var url = getURLString("/doc/deleteDocAction");
		ajaxCallServer(url, param, function(data){
			if(opener.window.search){
				opener.window.search();				
			}
		}, true);
	});
}
// 문서 폐기
function discardDoc(){
	openConfirm("${tl:getMessage('폐기하시겠습니까?')}", function(){
		
		var param = new Object();
		
		param.oid = "${doc.oid}";
		param.appState = "WITHDRAWN";
		
		var url = getURLString("/doc/withdrawnDocAction");
		ajaxCallServer(url, param, function(data){
			if(opener.window.search){
				opener.window.search();				
			}
		}, true);
	});
}
// 문서 개정
function reviseDoc(){
openConfirm("${tl:getMessage('개정하시겠습니까?')}", function(){
		
		var param = new Object();
		
		param.oid = "${doc.oid}";
		param.appState = "TEMP_STORAGE";
		
		var url = getURLString("/doc/reviseDocAction");
		ajaxCallServer(url, param, function(data){
			if(opener.window.search){
				opener.window.search();				
			}
		}, true);
	});
}
function loadIncludePage(tab) {
	
	if(tab == null) {
		tab = $(".tap>ul>li:first");
	}
	
	$(".tap ul li").removeClass("on");
	
	$(tab).addClass("on");
	
	var url = $(tab).data("url");
	var param = $(tab).data("param");
	
	if(param == null) {
		param = new Object();
	}
	
	param["oid"] = "${doc.oid}";
	$("#includePage").load(url, param);
}
</script>
<!-- pop -->
<div class="pop">
	<!-- top -->
	<div class="top">
		<h2><%-- ${doc.icon} --%> ${tl:getMessage('문서')} - ${doc.number}, ${doc.name}, ${doc.version}</h2>
		<c:if test="${!doc.lastVersionBtn()}">
			<span style="padding-top:5px;padding-left:5px;">
				<button type="button" class="s_bt03" style="height:30px;" onclick="openView('${doc.lastVersionOid()}')">${tl:getMessage('최신 버전 보기')}</button>
			</span>
		</c:if>
		<span class="close"><a href="javascript:window.close()"><img src="/Windchill/jsp/portal/images/colse_bt.png"></a></span>
	</div>
	<!-- //top -->

	<!--tap -->
	<div class="tap pt20">
		<ul>
			<li onclick="loadIncludePage(this);" data-url="${tl:getURLString('/doc/include_detailDoc')}">${tl:getMessage('세부 내용')}</li>
			<li onclick="loadIncludePage(this);" data-url="${tl:getURLString('/doc/include_relatedObject')}">${tl:getMessage('관련 객체')}</li>
			<li onclick="loadIncludePage(this);" data-url="${tl:getURLString('/doc/include_relatedProjectEChange')}">${tl:getMessage('프로젝트/설계변경')}</li>
			<li onclick="loadIncludePage(this);" data-url="${tl:getURLString('/common/include_integratedHistory')}" data-param='{"gridHeight":"500","autoGridHeight":"false"}'>${tl:getMessage('이력')}</li>
		</ul>
		<div class="tapbutton">
			<c:if test="${doc.modifyBtn()}">
				<button type="button" class="i_update" style="width: 70px;" onclick="javascript:modifyDoc()">${tl:getMessage('수정')}</button>
			</c:if>
			<c:if test="${doc.modifyBtn()}">
				<button type="button" class="i_delete" style="width: 70px;" onclick="javascript:deleteDoc()">${tl:getMessage('삭제')}</button>
			</c:if>
			<c:if test="${doc.reviseBtn()}">
				<button type="button" class="i_create" style="width: 70px;" onclick="javascript:reviseDoc()">${tl:getMessage('개정')}</button>
			</c:if>
		</div>
	</div>
	<!--//tap -->
	
	<div class="con pl25 pr25 pb15" id="includePage">
	</div>
</div>		
<!-- //pop-->