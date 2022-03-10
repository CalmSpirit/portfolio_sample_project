<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!-- 각 화면 개발시 Tag 복사해서 붙여넣고 사용할것 -->    
<%@ taglib prefix="c"		uri="http://java.sun.com/jsp/jstl/core"			%>
<%@ taglib prefix="tl" 	uri="/WEB-INF/tlds/tl-functions.tld"%>
<script>
$(document).ready(function(){
	//팝업 리사이즈
	popupResize();
});
</script>
<br/>
<div class="seach_arm2 pt10 pb5">
	<div class="leftbt">
		<!-- <h4><img class="pointer" onclick="switchPopupDiv(this);" src="/Windchill/jsp/portal/images/minus_icon.png"> ${tl:getMessage('기본 정보')}</h4> -->
		<h4><img class="" src="/Windchill/jsp/portal/images/t_icon.png"> ${tl:getMessage('기본 정보')}</h4>
	</div>
	<div class="rightbt"></div>
</div>
<!-- pro_table -->
<div class="pro_table">
	<table class="mainTable">
		<colgroup>
			<col style="width:15%">
			<col style="width:35%">
			<col style="width:15%">	
			<col style="width:35%">			
		</colgroup>
		<tbody>
			<tr>
				<th scope="col">${tl:getMessage('문서 분류')}</th>
				<td colspan="3">${doc.location}</td>
			</tr>
			<tr>
				<th scope="col">${tl:getMessage('문서 속성')}</th>
				<td>${doc.docAttributeName}</td>
				<th scope="col">${tl:getMessage('문서 구분')}</th>
				<td>${doc.docType}</td>
			</tr>
			<tr>
				<th scope="col">${tl:getMessage('문서 번호')}</th>
				<td>${doc.number}</td>
				<th scope="col">${tl:getMessage('문서 명')}</th>
				<td>${doc.name}</td>
			</tr>
			<tr>
				<th scope="col">${tl:getMessage('버전')}</th>
				<td>${doc.version}</td>				
				<th scope="col">${tl:getMessage('상태')}</th>
				<td>${doc.stateName}</td>	
			</tr>	
			<tr>
				<th scope="col">${tl:getMessage('등록자')}</th>
				<td>${doc.creatorFullName}</td>	
				<th scope="col">${tl:getMessage('등록일')}</th>
				<td>${doc.createDate}</td>
			</tr>	
			<tr>
				<th scope="col">${tl:getMessage('수정자')}</th>
				<td>${doc.modifierFullName}</td>				
				<th scope="col">${tl:getMessage('수정일')}</th>
				<td>${doc.modifyDate}</td>					
			</tr>	
			<tr>
				<th scope="col">${tl:getMessage('설명')}</th>
				<td colspan="3" class="pd10">
					<div class="textarea_autoSize">
						<textarea name="description" id="description" readonly><c:out value="${doc.description }" escapeXml="false" /></textarea>
					</div>
				</td>								
			</tr>	
			<tr>
				<th scope="col">${tl:getMessage('주첨부파일')}</th>
				<td colspan="3">
			 		<jsp:include page="${tl:getIncludeURLString('/content/include_fileView')}" flush="true">
						<jsp:param name="oid" value="${doc.oid}"/>
						<jsp:param name="type" value="PRIMARY"/>
					 </jsp:include>
			 	</td>								
			</tr>	
			<tr>
				<th scope="col">${tl:getMessage('부첨부파일')}</th>
				<td colspan="3">
				<jsp:include page="${tl:getIncludeURLString('/content/include_fileView')}" flush="true">
						<jsp:param name="oid" value="${doc.oid}"/>
					 </jsp:include>
				</td>								
			</tr>	
		</tbody>
	</table>	
	

</div>
