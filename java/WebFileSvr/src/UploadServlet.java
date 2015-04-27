
import javax.servlet.*;
import javax.servlet.http.*;

import java.io.*;
import java.util.*;

import org.apache.commons.fileupload.*;
import org.apache.commons.fileupload.servlet.*;
import org.apache.commons.fileupload.disk.*;

import com.google.gson.JsonObject;

/**
 * Servlet implementation class UploadServlet
 */
public class UploadServlet extends HttpServlet {
	/**
	   * 
	   */
	private static final long serialVersionUID = 1L;
	
	private String filePath; // 文件存放目录
	private String finalFilePath; // 上传成功的文件路径
	private String tempPath; // 临时文件目录	
	private String fileURL;

	// 初始化
	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		// 从配置文件中获得初始化参数
		fileURL = config.getInitParameter("filepath");
		filePath = config.getInitParameter("filepath");
		tempPath = config.getInitParameter("temppath");
		
		System.out.println(filePath);
		System.out.println(tempPath);
		

		ServletContext context = getServletContext();
		
				
		filePath = context.getRealPath(filePath);
		tempPath = context.getRealPath(tempPath);

		// 如果路径不存在，则创建路径
		File pathFile = new File(filePath);
		File pathTemp = new File(tempPath);
		if (!pathFile.exists()) {
			pathFile.mkdirs();
		}
		if (!pathTemp.exists()) {
			pathTemp.mkdirs();
		}
		System.out.println("文件存放目录、临时文件目录准备完毕 ...");
	}

	// doPost
	public void doPost(HttpServletRequest req, HttpServletResponse res)
			throws IOException, ServletException {
		
		finalFilePath =  req.getServerName() + ":" + String.valueOf(req.getServerPort()) + req.getContextPath() + fileURL + "/";
        
        System.out.println("ip + port:" +  req.getServerName() + ":" + req.getServerPort());
        
        System.out.println("URI:" +  req.getRequestURI());
        System.out.println("getContextPath:" +  req.getContextPath());
        
		System.out.println("finalFilePath:" +  finalFilePath);
		
		res.setContentType("text/plain;charset=utf8");
		PrintWriter pw = res.getWriter();
		try {
			DiskFileItemFactory diskFactory = new DiskFileItemFactory();
			// threshold 极限、临界值，即硬盘缓存 1G
			diskFactory.setSizeThreshold(1000 * 1024 * 1024);
			// repository 贮藏室，即临时文件目录
			diskFactory.setRepository(new File(tempPath));

			ServletFileUpload upload = new ServletFileUpload(diskFactory);
			// 设置允许上传的最大文件大小 1G
			upload.setSizeMax(1000 * 1024 * 1024);
			// 解析HTTP请求消息头
			List<FileItem> fileItems = upload
					.parseRequest(new ServletRequestContext(req));
			Iterator<FileItem> iter = fileItems.iterator();
			while (iter.hasNext()) {
				FileItem item = (FileItem) iter.next();
				if (item.isFormField()) {
					System.out.println("处理表单内容 ...");
					processFormField(item, pw);
				} else {
					System.out.println("处理上传的文件 ...");
					processUploadFile(item, pw);
				}
			}// end while()

			pw.close();
		} catch (Exception e) {
			System.out.println("使用 fileupload 包时发生异常 ...");
			e.printStackTrace();
		}// end try ... catch ...
	}// end doPost()

	// 处理表单内容
	private void processFormField(FileItem item, PrintWriter pw)
			throws Exception {
		String name = item.getFieldName();
		String value = item.getString();
		System.out.println(name + " : " + value + "\r\n");
		//pw.println(name + " : " + value + "\r\n");
	}

	// 处理上传的文件
	private void processUploadFile(FileItem item, PrintWriter pw)
			throws Exception {
		// 此时的文件名包含了完整的路径，得注意加工一下
		String filename = item.getName();
		
		System.out.println("完整的文件名：" + filename);
		int index = filename.lastIndexOf("\\");
		filename = filename.substring(index + 1, filename.length());

		long fileSize = item.getSize();

		if ("".equals(filename) && fileSize == 0) {
			System.out.println("文件名为空 ...");
			return;
		}

		File uploadFile = new File(filePath + "/" + filename);
		if (!uploadFile.exists()) {
			uploadFile.createNewFile();
		}
		item.write(uploadFile);
		
		JsonObject ret = new JsonObject();
		ret.addProperty("url", finalFilePath + filename);
		ret.addProperty("size", fileSize);
		ret.addProperty("result", 0);
		pw.append(ret.toString());
	}

	// doGet
	public void doGet(HttpServletRequest req, HttpServletResponse res)
			throws IOException, ServletException {
		doPost(req, res);
	}

}
