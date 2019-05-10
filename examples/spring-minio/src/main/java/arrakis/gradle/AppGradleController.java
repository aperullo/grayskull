package arrakis.gradle;

import io.minio.Result;
import io.minio.errors.MinioException;
import io.minio.messages.Item;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import org.slf4j.Logger;
import io.minio.MinioClient;
import org.slf4j.LoggerFactory;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.xmlpull.v1.XmlPullParserException;

@RestController
public class AppGradleController {

  Logger logger = LoggerFactory.getLogger(AppGradleController.class);
  private Properties properties = new Properties();

  @PostMapping("/objects")
  public String PostItem(@Validated FileUpload file) throws IOException {

    MultipartFile multipartFile = file.getFile();
    String fileName = multipartFile.getOriginalFilename();
    String fileType = multipartFile.getContentType();
    InputStream fileStream = new ByteArrayInputStream(
        file.getFile().getBytes());

    String response;

    try {
      MinioClient minioClient = new MinioClient(properties.SERVER_ADDRESS,
          properties.ACCESS, properties.SECRET);

      if(fileStream.available() > 0 && minioClient
          .bucketExists(properties.BUCKET_NAME)) {

        minioClient.putObject(properties.BUCKET_NAME,
          fileName, fileStream, fileType);

        response = "Upload successful: " + fileName;
      } else {
        response = "Upload unsuccessful: " + fileName;
      }

    } catch(MinioException | IOException | NoSuchAlgorithmException
        | InvalidKeyException | XmlPullParserException e) {
      logger.error("POST broke: ", e);
      response = "upload not successful";
    }
    return response;
  }

  @GetMapping("/objects")
  @ResponseBody
  public String GetItem() {

    ArrayList<Object> ls = new ArrayList();
    Iterable<Result<Item>> objects;

    try {
      MinioClient minioClient = new MinioClient(properties.SERVER_ADDRESS,
              properties.ACCESS, properties.SECRET);

      if (minioClient.bucketExists(properties.BUCKET_NAME)) {

        objects = minioClient.listObjects(properties.BUCKET_NAME);

        for (Result<Item> result : objects) {
          Item item = result.get();
          ls.add(item.objectName());
        }
      }

    } catch (MinioException | IOException | InvalidKeyException |
        NoSuchAlgorithmException | XmlPullParserException e) {
      logger.error("GET broke: ", e);
    }
    return ls.toString();
  }
}