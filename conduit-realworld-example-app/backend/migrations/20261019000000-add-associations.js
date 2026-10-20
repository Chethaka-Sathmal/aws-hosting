"use strict";
// Foreign keys and join tables defined by the model associations, which the
// earlier migrations never created (they only existed via sequelize.sync).
module.exports = {
  async up(queryInterface, Sequelize) {
    const foreignKey = (model, onDelete) => ({
      type: Sequelize.INTEGER,
      references: { model, key: "id" },
      onDelete,
      onUpdate: "CASCADE",
    });
    const joinKey = (model, key = "id", type = Sequelize.INTEGER) => ({
      type,
      allowNull: false,
      primaryKey: true,
      references: { model, key },
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    });

    // Articles
    await queryInterface.addColumn(
      "Articles",
      "userId",
      foreignKey("Users", "SET NULL"),
    );

    // Comments
    await queryInterface.addColumn(
      "Comments",
      "articleId",
      foreignKey("Articles", "CASCADE"),
    );
    await queryInterface.addColumn(
      "Comments",
      "userId",
      foreignKey("Users", "SET NULL"),
    );

    // Tag list
    await queryInterface.createTable("TagList", {
      articleId: joinKey("Articles"),
      tagName: joinKey("Tags", "name", Sequelize.STRING),
    });

    // Favorites
    await queryInterface.createTable("Favorites", {
      articleId: joinKey("Articles"),
      userId: joinKey("Users"),
    });

    // Followers
    await queryInterface.createTable("Followers", {
      userId: joinKey("Users"),
      followerId: joinKey("Users"),
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable("Followers");
    await queryInterface.dropTable("Favorites");
    await queryInterface.dropTable("TagList");
    await queryInterface.removeColumn("Comments", "userId");
    await queryInterface.removeColumn("Comments", "articleId");
    await queryInterface.removeColumn("Articles", "userId");
  },
};
